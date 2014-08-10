// test_tun.click

// This user_level configuration tests the KernelTun element, which
// accesses the Linux Universal Tun/Tap device, *BSD's /dev/tun* devices,
// or Linux's Ethertap devices (/dev/tap*).  These devices let user_level
// programs trade packets with kernel IP processing code.  You will need to
// run it as root.
//
// This configuration should work on FreeBSD, OpenBSD, and Linux.  It should
// produce a stream of 'tun_ok' printouts if all goes well.  On OpenBSD, you
// may need to run
//	route add 1.0.0.0 -interface 1.0.0.1
// after starting the Click configuration.
//
// Also try running 'ping 1.0.0.2' (or any other host in 1.0.0.1/8 except
// for 1.0.0.1).  Click should respond to those pings, and print out a
// 'tun_ping' message for each ping received.

tun :: KernelTun(1.0.0.1/8);

ICMPPingSource(1.0.0.2, 1.0.0.1)
    -> tunq :: Queue -> tun;

tun -> ch :: CheckIPHeader
    -> ipclass :: IPClassifier(icmp type echo, icmp type echo_reply);
    
ipclass[0] -> ICMPPingResponder
    -> IPPrint(tun_ping)
    -> tunq;

ipclass[1] -> IPPrint(tun_ok) -> Discard;

ch[1] -> Print(tun_bad) -> Discard;
tun[1] -> Print(tun_nonip) -> Discard;

