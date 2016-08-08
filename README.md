if_vether(4) - port for FreeBSD 10.x-RELEASE
--------------------------------------------
 
Virtual Ethernet interface, ported from OpenBSD. This interface 
operates in conjunction with if_bridge(4).

Suppose instance of if_vether(4) denotes ifp0 and ifp denotes 
different Ethernet NIC, which is member of instance of if_bridge(4) 
where ifp0 is member.  

Frame output:

<pre><code>
     + inet_output()             + ng_ether_rcv_lower()
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
     + bridge_input(), but forwarding is stalled by
     |           
     |                  if (ifp0->if_type == IFT_VETHER)
     |                          return (m);
     v
     + ether_demux() 
</code></pre>

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=hmatyschok&url=https://github.com/hmatyschok/MeshBSD&title=MeshBSD&language=&tags=github&category=software) Please feel free to support me anytime.
