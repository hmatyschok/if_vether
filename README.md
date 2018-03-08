if_vether(4) - port for FreeBSD 11.x-RELEASE
--------------------------------------------

<pre><code> 
 Virtual Ethernet interface, ported from OpenBSD. This interface 
 operates in conjunction with if_bridge(4).

 Suppose instance of if_vether(4) denotes ifp0 and ifp denotes 
 different Ethernet NIC, which is member of instance of if_bridge(4) 
 where ifp0 is member. his interface still utilizes by if_bridge(4) 
 implemented Service Access Point [SAP] for transmitting frames

   extern	struct mbuf *(*bridge_input_p)(struct ifnet *,
	struct mbuf *);

   extern	int (*bridge_output_p)(struct ifnet *, struct mbuf *,
	struct sockaddr *, struct rtentry *);
 
 whose are either used by

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

  brocedure, see ifnet(9) and net/if_var.h for further details. On 
  case of if_vether(4), therefore  
  
   static void 	vether_start(struct ifnet *);
  
  will be called by if_transmit(9) or on the other hand  by
  
   int 	ether_output_frame(struct ifnet *, struct mbuf *);
  
  finally, when either an instance of if_vether(4) is 
  not if_bridge(4) member or
  
   static int 	ng_ether_rcv_lower(hook_p, item_p)

  transmitted a frame. Any by if_vether(4) transmitted frame
  still passes on bridge_output_p(9) mapped procedure shall 
  annotated by M_VETHER flag for internal processing by 
  
   static void 	vether_start_locked(struct vether_softc	*, 
	struct ifnet *);
	
  if and only if 
  
   static int 	vether_bridge_output(struct ifnet *, 
	struct mbuf *, struct sockaddr *, struct rtentry *);
     
  maps to SAP on if_bridge(4) for transmitting mbuf(9)s 
  carrying frame. Finally, on reception 

  struct mbuf *	vether_bridge_input(struct ifnet *,
	struct mbuf *);
  
  encapsulates 
  
   struct mbuf *	bridge_input(struct ifnet *,
	struct mbuf *);
    
  maps to on SAP on if_bridge(4). Therefore, in avoidance of 
  occouring a so called broadcast storm, any by if_vether(4)
  received frame shall never forwarded by if_bridge(4).
   
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
             \     +-----------+ vether_start_locked()
              \   / 
               \ /
                + vether_bridge_output(), annotates tx'd frame
                |
                |     if (ifp->if_flags & IFF_VETHER)
   	            |         m->m_flags |= M_VETHER;
                |
                | 
                + bridge_output(), selects NIC for tx frames
                | 
                + bridge_enqueue()  
                |
                + (*ifp->if_transmit)()
                |
                v
                +-{ physical broadcast media } 
   
 Any tx'd frame from layer above, shall rx'd by 
 
   static void 	ether_input_internal(struct ifnet *, struct mbuf *);
   
 on if_vether(4), because any by if_bridge(4) broadcasts those to 
 its assoiciated member. This will be ensured that any by higher 
 layer above emmitted frame shall annotated by

   #define M_VETHER 	M_UNUSED_8

 flag, see mbuf(9) and sys/mbuf.h for further details. 
   
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
       + vether_start_locked()
        \     
         + (*ifp0->if_input)() 
        / \
       /   +--->+ ng_ether_input()  
      /
     + vether_bridge_input(), but forwarding is stalled by
     |           
     |                if (ifp->if_flags & IFF_VETHER) {
     |                    eh = mtod(m, struct ether_header   );
     |
     |                    if (memcmp(IF_LLADDR(ifp), 
     |                        eh->ether_shost, ETHER_ADDR_LEN) == 0) {
     |                        m_freem(m);
     |                           return (NULL);
     |                    }
     |                    m->m_flags &= ~M_VETHER;
     |
     |                    return (m);		
     |                }
     |
     v
     + ether_demux()
</code></pre>

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=hmatyschok&url=https://github.com/hmatyschok/MeshBSD&title=MeshBSD&language=&tags=github&category=software) Please feel free to support me anytime.
