// udpcount.click

// This file is a simple UDP/IP packet counter, meant to be used in the
// Linux kernel module. It counts UDP packets received on port 1234. (Change
// the argument to 'ip_classifier' to use a different port.) See
// 'udpgen.click' for a traffic generator corresponding to udpcount.click.

// Change the following line to refer to your interface's IP and Ethernet
// addresses.
AddressInfo(the_interface 1.0.0.1 0:0:c0:8a:67:ef);

classifier	:: Classifier(12/0800 ,
			      12/0806 20/0001 ,
			      - );
ip_classifier	:: IPClassifier(dst udp port 1234 ,
				- );
in_device	:: PollDevice(the_interface);
out		:: Queue(200) -> ToDevice(the_interface);
to_host		:: ToHost;
ctr		:: Counter ;

in_device -> classifier
	-> CheckIPHeader(14, CHECKSUM false) // don't check checksum for speed
	-> ip_classifier
	-> ctr
	-> Discard;
classifier[1] -> ARPResponder(the_interface) -> out;
classifier[2] -> to_host;
ip_classifier[1] -> to_host;
