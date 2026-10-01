import QtQuick
import Quickshell.Io

Item {
    id: root

    property real cpu: 0
    property real memory: 0
    property real disk: 0
    property real downKiB: 0
    property real upKiB: 0

    // Smoothed transfer rates. The raw per-interval figure is honest but very
    // jumpy at a 1s poll -- a single burst is the whole reading, then nothing --
    // so what is shown is an exponential average over the last few ticks. 0.4
    // weights the newest sample at 40%, which settles in about two seconds:
    // steady enough to read, quick enough not to lie about a transfer stopping.
    property real smoothDown: 0
    property real smoothUp: 0

    // The combined rate that fills the network ring.
    //
    // A fixed ceiling cannot work for a rate: too low and a fast link pins at
    // full with no way to tell 100 MiB/s from 2 GiB/s, too high and an ordinary
    // link sits permanently near empty. So this follows the traffic -- up
    // immediately, down slowly, with a floor so an idle link is not amplified
    // into a jittery full ring. Growth is instant because a burst should be
    // visible while it happens; the decay is deliberately lazy so the ring does
    // not breathe every time a transfer pauses.
    property real netCeiling: 512

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real previousRx: 0
    property real previousTx: 0
    property double previousSampleTime: 0

    function parseSample(sample) {
        const parts = sample.trim().split("|");
        if (parts.length < 4)
            return ;

        const cpuParts = parts[0].trim().split(/\s+/);
        const total = Number(cpuParts[0]);
        const idle = Number(cpuParts[1]);
        if (previousCpuTotal > 0 && total > previousCpuTotal) {
            const busy = (total - previousCpuTotal) - (idle - previousCpuIdle);
            cpu = Math.max(0, Math.min(1, busy / (total - previousCpuTotal)));
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
        const memoryParts = parts[1].trim().split(/\s+/);
        const memTotal = Number(memoryParts[0]);
        const memAvailable = Number(memoryParts[1]);
        if (memTotal > 0)
            memory = Math.max(0, Math.min(1, 1 - memAvailable / memTotal));

        disk = Math.max(0, Math.min(1, Number(parts[2]) / 100));

        const networkParts = parts[3].trim().split(/\s+/);
        const received = Number(networkParts[0]);
        const sent = Number(networkParts[1]);
        const now = Date.now();
        if (previousSampleTime > 0 && now > previousSampleTime) {
            const seconds = (now - previousSampleTime) / 1000;

            // A counter that went backwards means an interface was recreated or
            // dropped, not that traffic reversed. Reporting the difference
            // anyway would read as a hard zero for that tick -- a fake pause in
            // the middle of a transfer -- so this sample is skipped instead.
            if (received >= previousRx && sent >= previousTx) {
                const instantDown = (received - previousRx) / 1024 / seconds;
                const instantUp = (sent - previousTx) / 1024 / seconds;

                smoothDown = smoothDown === 0
                    ? instantDown
                    : smoothDown + (instantDown - smoothDown) * 0.4;

                smoothUp = smoothUp === 0
                    ? instantUp
                    : smoothUp + (instantUp - smoothUp) * 0.4;

                downKiB = smoothDown;
                upKiB = smoothUp;

                // Track the peak for the ring, up at once and down slowly. The
                // 0.9 decay compounds once per tick, so the ceiling takes about
                // half a minute to walk back down after a burst, which is what
                // stops the ring pulsing on every gap between transfers.
                const total = downKiB + upKiB;
                if (total > netCeiling)
                    netCeiling = total;
                else if (total < netCeiling * 0.35)
                    netCeiling = Math.max(512, netCeiling * 0.9);
            }
        }
        previousRx = received;
        previousTx = sent;
        previousSampleTime = now;
    }

    visible: false
    width: 0
    height: 0

    Process {
        id: poller

        // Four samples in one shell, so the whole tick is a single fork and one
        // pipe read.
        //
        // The network half used to read $3/$11 out of /proc/net/dev with
        // -F'[: ]+', which was quietly wrong. The kernel pads short interface
        // names with leading spaces to a fixed column, and a regex field
        // separator does not collapse a leading run the way the default one
        // does. So the name landed in $1 for a long name and in $2 for a short
        // one, and every index after it shifted by one. Measured on this
        // machine: for enp0s25 the old expression read 597851 where the true
        // receive figure was 316305769 -- it was summing *packet counts* for
        // that adapter, and summing *bytes* only for lo, which happened to be
        // padded. No combination of those two is a network speed.
        //
        // Using the default field separator makes the columns land in the same
        // place regardless of how the name is padded: $1 is always the name,
        // $2 the receive bytes, $10 the transmit bytes (there are eight receive
        // columns in between). Cross-checked against `ip -s link`, which reads
        // the same kernel counters: exact agreement to the byte.
        //
        // Loopback and the virtual adapters are excluded as well. Loopback is
        // the machine talking to itself, not the network, and a tunnel or
        // bridge is already counted on the physical link it rides on, so
        // summing it would count a tailscale or vmware transfer twice. Real
        // adapters -- wired and wireless both -- still add up, because when two
        // are up they are carrying distinct traffic.
        command: ["sh", "-c", "awk '/^cpu / {printf \"%.0f %.0f|\", $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat; awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {printf \"%.0f %.0f|\", t, a}' /proc/meminfo; df -P / | awk 'NR==2 {gsub(/%/, \"\", $5); printf \"%s|\", $5}'; awk 'NR>2 { n = $1; if (n == \"lo:\") next; if (n ~ /^(docker|veth|br-|bridge|virbr|vmnet|vboxnet|tun|tap|tunl|wg|wg-|zt|ztun|ham|tailscale|teql|ifb|dummy|bond-slave):/) next; rx += $2; tx += $10 } END {printf \"%.0f %.0f\\n\", rx, tx}' /proc/net/dev"]

        stdout: StdioCollector {
            onStreamFinished: root.parseSample(text)
        }

    }

    Timer {
        // 1s. The old 5s was coarse enough that a transfer which started and
        // stopped between two ticks never showed up at all, and a 5s average
        // says nothing about what is happening right now. The cost is one
        // shell plus four small awk runs per second, all reading /proc, which
        // is a few milliseconds of work.
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!poller.running)
                poller.running = true;

        }
    }

}
