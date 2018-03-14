if_vether(4) for FreeBSD and if_bridge(4) [v 1.31]
--------------------------------------------------

<pre><code> 
 Virtual Ethernet interface, ported from implementation of vether(4) 
 [v 1.29] created by the OpenBSD project. This interface operates in 
 conjunction with if_bridge(4), v 1.31.

 Suppose an instance of if_vether(4) denotes ifp0 and ifp denotes 
 different Ethernet NIC or interrface, which is member on instance 
 of if_bridge(4) where ifp0 is its member also too. 
 
      + xxx_output()              + ng_ether_rcv_lower()
     |                           |
     v                           | 
     + (*ifp0->if_output)()      |
      \                          v   
       \                         + ether_output_frame()
        \                        |
         \                       + (*ifp0->if_transmit)()
          \                      |
           \                     + (*ifp0->if_start)()
            \                   /
             \     +-----------+ vether_start()
              \   / 
               \ / 
                + bridge_output(), selects NIC for tx frames
                | 
                + bridge_enqueue()  
                |
                + (*ifp->if_transmit)()
                |
                v
                +-{ physical broadcast media } 
 
 This interface still utilizes by if_bridge(4) implemented Service 
 Access Point [SAP] for receiving 
 
   extern	int (*bridge_output_p)(struct ifnet *, struct mbuf *,
	struct sockaddr *, struct rtentry *);
 
 and transmitting frames

   extern	struct mbuf *(*bridge_input_p)(struct ifnet *,
	struct mbuf *);
	
 like other Ethernet interfaces whose are either used by

   int 	ether_output(struct ifnet *ifp, struct mbuf *,
	const struct sockaddr *, struct route *); 

 for transmitting frames or by
 
   static void 	ether_input_internal(struct ifnet *, struct mbuf *);
    
 for receiving frames. Any transmitted mbuf(4) still passes
 
   static int 	bridge_output(struct ifnet *, struct mbuf *, 
		struct sockaddr *, struct rtentry *);
  
  maps to bridge_output_p(9) shall enqueued and transmitted throught 
    
   static int 	bridge_enqueue(struct bridge_softc *, 
		struct ifnet *, struct mbuf *);

  by if_bridge(4) on selected interface via call of its mapped
  
   static int 	if_transmit(struct ifnet *, struct mbuf *);   

  procedure, see ifnet(9) and net/if_var.h for further details. On 
  case of if_vether(4), therefore  
  
   static void 	vether_start(struct ifnet *);
  
  will be called by if_transmit(9) or on the other hand  by
  
   int 	ether_output_frame(struct ifnet *, struct mbuf *);
  
  finally, when either an instance of if_vether(4) is 
  not if_bridge(4) member or
  
   static int 	ng_ether_rcv_lower(hook_p, item_p)

  transmitted a frame. Any tx'd frame from layer above shall rx'd by 
 
   static void 	ether_input_internal(struct ifnet *, struct mbuf *);
   
 on if_vether(4), because any by if_bridge(4) broadcasts those to 
 its assoiciated member.
   
     +-{ physical broadcast media } 
     |
     v
     + (*ifp->if_input)(), NIC rx frame 
     |
     + vether_bridge_input()
     |
     + bridge_input()
     |                           
     + bridge_forward(), selects ifp0 denotes instance of if_vether(4)
     |
     + bridge_enqueue()
     |
     + (*ifp0->if_transmit)()
      \            
       + vether_start()
        \     
         + (*ifp0->if_input)() 
        / \
       /   +--->+ ng_ether_input()  
      /
     + bridge_input()
     |
     v
     + ether_demux()
</code></pre>
     
Legal Notice: 
-------------
 
<pre><code>
  (a) FreeBSD is a trademark of the FreeBSD Foundation.
   
  (b) OpenBSD is a trademark of Theo DeRaadt.  
</code></pre>

Additional information about contacting
---------------------------------------
      
If someone wants to contact me by electronic mail, use encryption!

<pre><code>
Otherwise, any connection attempt will be discarded. 
</code></pre>

This is a necessary security measure, because I would like to know 
who is contacting me, because of this planet is full of individuals 
whose are operating on one's own merits and this imply that this 
planet is not a so called "Ponyhof", unfortunately. :)

<pre><code>
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBFYMezIBCACo8X47yor6hI3Rwd2vYr+R2f35ZJw1Zq6qzQXYhWhn2CNf4gYJ
5+hEBi5LJcSFhSvujo/xy3OZzL8a4YN/vFWGTZhuyk20MOx96yjzLLbXD9lxHd+a
AoSPuPe78QSTAw7azv7PtUSTnH0KzLCC2Rh1yODYmU4bBw5Aeso/mmWNebh6hd7r
Azp3ruLji1YorWTUHWWDbq+EsB3bSvNq6hmGiOnTsWlhhdOre4ny0OD0Tig6OgFR
S3fkzofnroJN21MdAgofksaeClzdEgSDor1Yk/tcdCHRu4/kHEdEljD6YdpzWbKx
f6BsqMFLHKrksEF8H7oH+Cq3izXOeziy9TsVABEBAAG0Okhlbm5pbmcgTWF0eXNj
aG9rIDxoZW5uaW5nLm1hdHlzY2hva0BzdHVkLmZoLWZsZW5zYnVyZy5kZT6JATcE
EwEIACEFAlYMezICGwMFCwkIBwIGFQgJCgsCBBYCAwECHgECF4AACgkQzcSBpLKQ
n3Xocgf8Dcp8MoACABJbUDMHGzFOScLhSugj6zcWZVJ96Uyj1B4yrshk1GiSOid5
OkY+g0BLZDsZ6L/ikY55jh4FMRw6Ox6sh2NX1rT4TVVkJJwiG6KLTwvLpqknaRXX
SoSKRt+U2JYhVLX8UY5TGlqtz5jtUm6jB8i2W64EFXYGl161rELEYmpienHvrFH7
rDMIHdBNlc4bJRiJU/qN5/28+BPjnFmG2/xVv7NlnH01GTPIXx2WfmkcgqNnleZS
d74iTejqFtB3jMws9zSCgLK5G684YeFJbN0mYdnZ+JonwaGti4oV91Ey/1NN0dHH
dgiA/njv+Sf17fwDxHLcj7RMesjZ7bkBDQRWDHsyAQgAyZyyysgBBysI0UqYL/27
1mNWABM3Ok6MinkrCy/oeqvp0zj4xocfzvjqpNEC9R2tzIxCtni+c1T2a4eoLSvu
G2TRrncPxHSxvGCClwQxlkS5INp4Y2NCEq4s+Fo0OyTawXGTTTgNEPK8yviK+0nh
jcpEcCNhGMArkNR6G0W6M2k6v3k0A2fMJ0ARFFj85kpbPv1IMGLs8HbWUe2D/1KQ
rJsCGU5tjiOXYL1/KfXDBhfw+fwC5AM+Ndxlhpla3Z+0RaxCjvQT7Z501U311aMh
kbfmS+Llvq3cZNDleNkWkHsWYgYL4wZqnrVQDfeqzL+moFjBHtLn+ZZbLn6OYc1f
qQARAQABiQEfBBgBCAAJBQJWDHsyAhsMAAoJEM3EgaSykJ91zKoH/jzxQSy7pUZx
Pe4ktFRJwil8g6CGUncVaV+Sxe0A+52dlk85W/4F+wMROvg5tc98uZeLH8Ye0BSI
EDwJD5Iel9qI+qQegqzvGkjuJzZx86XhFWBa8dmIzRgqeAZrblmpv9k5V1cyMSUO
2v/GaJOu3P9Jb9RPR0YVsiZTs3+R1Z6V05pBdbMG5bUVHvjEIFahmHKc+cvxwjPV
wY7U3JsZk7bYZG05pUstLIuNJ//UMVjC/dM6ofKTyLknbKDYKvJvcmPBSSeC7VXg
u5E2GRq1FgrjmjTS8r+/zZfV31iFkIdc5gC9ipwBsA7H6Bx8lPP5M0l1MXS/wAWU
8GZ4NRztiBU=
=lsmx
-----END PGP PUBLIC KEY BLOCK-----
</code></pre>
