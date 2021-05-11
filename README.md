<pre><code> 
if_vether(4) for FreeBSD and if_bridge(4) [v 1.31]
==================================================

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
   
Legal Notice: 
-------------
 
  (a) FreeBSD is a trademark of the FreeBSD Foundation.
   
  (b) OpenBSD is a trademark of Theo DeRaadt.  

</code></pre>
