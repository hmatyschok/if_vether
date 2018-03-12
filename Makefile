
.PATH:	${.CURDIR}/src
KMOD=	if_vether
SRCS=	if_vether.c 

.include <bsd.kmod.mk>
