if_vether(4) - port for FreeBSD 11.x-RELEASE
--------------------------------------------
 
Virtual Ethernet interface, ported from OpenBSD. This interface 
operates in conjunction with if_bridge(4).

Suppose instance of if_vether(4) denotes ifp0 and ifp denotes 
different Ethernet NIC, which is member of instance of if_bridge(4) 
where ifp0 is member.  

Frame output:

<pre><code>
   
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
   
</code></pre>
Frame input:
<pre><code>
   
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

 In avoidance of so called [unknown] side-effects, the

<pre><code>
 
   #define	M_PROTO2	0x00002000 /* protocol-specific */

</code></pre>
 
 flag replaced by 

   #define	M_UNUSED_8	0x00000100 /* --available-- */

</code></pre>

 maps to

   #define M_VETHER 	M_UNUSED_8

</code></pre>

 see mbuf(9) and sys/mbuf.h for further details. This 
 interface still utilizes by if_bridge(4) implemented 
 Service Access Point [SAP] for transmitting frames

<pre><code>
 
   extern	struct mbuf *(*bridge_input_p)(struct ifnet *,
	struct mbuf *);

   extern	int (*bridge_output_p)(struct ifnet *, struct mbuf *,
	struct sockaddr *, struct rtentry *);

</code></pre>
 
 whose are either used by
 
<pre><code>
 
   int 	ether_output(struct ifnet *ifp, struct mbuf *,
	const struct sockaddr *, struct route *); 

</code></pre>

 for transmitting frames or by

<pre><code>

   static void 	ether_input_internal(struct ifnet *, struct mbuf *);

</code></pre>
    
 for receiving frames. Any transmitted mbuf(4) still passes

<pre><code>
 
   static int 	bridge_output(struct ifnet *, struct mbuf *, 
		struct sockaddr *, struct rtentry *);

</code></pre>
  
  maps to bridge_output_p(9) shall enqueued and transmitted throught 

<pre><code>
    
   static int 	bridge_enqueue(struct bridge_softc *, 
		struct ifnet *, struct mbuf *);

</code></pre>

  by if_bridge(4) on selected interface via call of its mapped

<pre><code>
  
   static int 	if_transmit(struct ifnet *, struct mbuf *);   

</code></pre>

  brocedure, see ifnet(9) and net/if_var.h for further details. On 
  case of if_vether(4), therefore  

<pre><code>
  
   static void 	vether_start(struct ifnet *);

</code></pre>
  
  will be called by if_transmit(9) or on the other hand  by

<pre><code>
  
   int 	ether_output_frame(struct ifnet *, struct mbuf *);

</code></pre>
  
  finally, when either an instance of if_vether(4) is 
  not if_bridge(4) member or 

<pre><code>
  
   static int 	ng_ether_rcv_lower(hook_p, item_p)

</code></pre>
    
  transmitted a frame. Any by if_vether(4) transmitted frame
  still passes on bridge_output_p(9) mapped procedure shall 
  annotated by M_VETHER flag for internal processing by 

<pre><code>
  
   static void 	vether_start_locked(struct vether_softc	*, 
	struct ifnet *);

</code></pre>

  if and only if 

<pre><code>
  
   static int 	vether_bridge_output(struct ifnet *, 
	struct mbuf *, struct sockaddr *, struct rtentry *);
 
 </code></pre>
     
  maps to SAP on if_bridge(4) for transmitting mbuf(9)s 
  carrying frame. Finally, on reception 

<pre><code>
  
   struct mbuf *	vether_bridge_input(struct ifnet *,
	struct mbuf *);

</code></pre>
  
  encapsulates 
 
<pre><code> 
 
   struct mbuf *	bridge_input(struct ifnet *,
	struct mbuf *);
  
</code></pre>  
  
  maps to on SAP on if_bridge(4). Therefore, in avoidance of 
  occouring a so called broadcast storm, any by if_vether(4)
  received frame shall never forwarded by if_bridge(4).


[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=hmatyschok&url=https://github.com/hmatyschok/MeshBSD&title=MeshBSD&language=&tags=github&category=software) Please feel free to support me anytime.
