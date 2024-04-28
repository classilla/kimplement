0 poke808,234:poke53280,0:poke53281,0:print"{S}";:poke2039,peek(186):sys51200
1 poke52,30:poke56,30:poke644,31:clr:open2,2,0,chr$(6)+chr$(0)
2 poke247,0:poke248,31:poke249,0:poke250,30:poke169,144
100 sr=49408:rs=49411:lt=51200:hx=lt+3:al=lt+6:poke22522,0:poke22523,28
101 forx=54272to54296:pokex,0:next:poke54296,15:poke54277,9:poke54278,0
102 poke53280,0:poke53281,5:print"{PShn}":poke650,64:poke53286,2
105 poke53271,255:poke53276,255:e=116:forx=0to14step2:poke53248+x,e
106 poke2040+x/2,128:poke54273,128:poke53287+x/2,0:poke53249+x,50:e=e+17:next
108 poke53264,0:poke53269,255:poke16625,0:d=peek(2039):ifd<8thend=8
110 print"{sqqq}The Incredible KIMplement for the C64"
120 print"1.0 * www.floodgap.com/retrobits/kim-1":print
130 print"Emulator code copyright (C) 2002-2024,"
140 print"Cameron Kaiser. All rights reserved."
150 print"KIM-1 ROM code copyright (C) 1975, MOS":print"Technology, Inc.{q}"
151 print"Press Commodore key for options."
160 print"<System reset>":syssr
170 e=peek(787):ife<254goto500
180 print:print"<Emulator paused>":poke53269,255:poke198,.
190 f=1:gosub1000:f=0:print"Press Commodore key again to reset, or"
#         #######################################
200 print"<R>esume <L>oad <S>ave <T>oggle Wedg<@>"
202 print"Device"d"(use <8>, <9>, 1<0>, 1<1>)"
210 geta$:z=peek(653):ifz<>2anda$=""goto210
220 ifz=2thenpoke53281,2:wait653,2,2:poke53281,5:goto160
230 ifa$="r"thenprint"<Emulator resumed>{q}":wait203,64:poke198,.:sysrs:goto170
240 ifa$="s"goto900
250 ifa$="l"goto800
251 ifa$="@"goto400
252 ifa$="0"ora$="1"ora$="8"ora$="9"goto350
260 ifa$<>"t"goto210
270 print"{q}Toggle switches (1=on):"
280 print"  <1> Use ROM SCANDS; toggle ="peek(rs+3)
290 print"  <2> Single-Step (SST); toggle ="peek(rs+6)
300 print"  <3> TTY on userport; toggle ="peek(rs+9)
310 print"  Done with <T>oggles"
320 geta$:ifa$<>"1"anda$<>"2"anda$<>"3"anda$<>"t"goto320
330 ifa$="t"goto180
340 v=rs+(asc(a$)-48)*3:pokev,(peek(v)+1)and1:goto270
350 nd=val(a$):ifnd<8thennd=nd+10
351 open15,nd,15:close15:ifstthenprint"?Device not present{q}":goto190
352 print"Device is now"nd"{q}":d=nd:goto190
#         #######################################
400 print"{q}Enter disk command, or $ for directory"
410 print"or no command to read error channel."
420 print"@";:gosub1500:poke53269,0:poke186,d:sys51712,x$:goto180
500 onegoto510,650,600,600
502 sysrs:goto170
510 poke253,peek(24574):poke254,peek(24575):sysrs:goto170
600 print:print"<Illegal instruction>":goto660
650 print:print"<Protection fault>"
660 gosub1000:print"Press any key to reset CPU.":poke198,.:wait198,1:geta$
670 goto160
800 print"{q}Enter blank filename to cancel.":print"Load: ";:gosub1500
810 ifx$=""goto180
811 poke53269,0:close15:open15,d,15,"r0:"+x$+"="+x$:input#15,n,m$,t,s:close15
812 ifn<>63andn<>0thenprintn"{|}, "m$","t"{|},"s:goto180
813 print" <K>IMplement PRG or raw <B>inary?"
814 geta$:ifa$<>"k"anda$<>"b"goto814
815 ifa$="k"goto840
820 f$=x$:print"Starting address in KIM RAM: $";:gosub1600:ifx$=""goto180
821 z$=left$(x$,1):ifz$<"0"orz$>"3"thenprint"$0000-3fff only!":goto820
822 gosub1700:sa=v+16384:close1:open1,d,2,f$:sysal,1:t=peek(196):u=peek(195)
823 close1:pokesa,u:pokesa+1,t:sa=sa+2:print" Loading ...{||||}";
824 sys57812f$,d,0:poke780,0:hb=int(sa/256):poke781,sa-hb*256:poke782,hb
825 poke157,0:sys65493:goto865
840 close1:open1,d,2,x$:sysal,1:t=peek(196):close1:ift>63andt<128goto860
850 close1:print"Illegal starting address (hb=";:syshx,t:print")":goto180
860 print"{q}sa=";:syshx,t*256+peek(195)-16384:print", Loading ...{||||}";
861 sys57812x$,d,1:poke780,0:poke157,0:sys65493
865 print", ea=";:e=peek(174)+peek(175)*256:e=e-16385:syshx,e:ife>16383goto875
870 print:goto180
875 print:print"Load exceeded bounds, corrupting":print"main emulator core!"
878 print"Reset 64 and reboot KIMplement.":cont
900 print"{q}Enter blank entry to cancel.":print"Save: ";:gosub1500
910 ifx$=""goto180
911 f$=x$
920 print"Starting address in KIM RAM: $";:gosub1600:ifx$=""goto180
930 z$=left$(x$,1):ifz$<"0"orz$>"3"thenprint"$0000-3fff only!":goto920
932 gosub1700:sl=vand255:sa=v+16384:s$=x$
940 print"Ending address in KIM RAM: $";:gosub1600:ifx$=""goto180
950 z$=left$(x$,1):ifz$<"0"orz$>"3"thenprint"$0000-3fff only!":goto940
960 print"Saving from $"s$" to $"x$" ...":gosub1700:v=v+1:el=vand255:ea=v+16384
#970 poke53269,0:sys57812f$,d,1:poke193,sl:poke194,sa/256:poke174,el:poke157,0
#980 poke175,ea/256:sys62954:close15:open15,d,15:input#15,n,m$,t,s:close15
970 poke53269,0:sys57812f$,d,1:poke193,sl:poke194,sa/256:poke781,el:poke157,0
980 poke782,ea/256:poke780,193:sys65496:close15
990 open15,d,15:input#15,n,m$,t,s:close15:printn"{|}, "m$","t"{|},"s:goto180
1000 pc=peek(253)+256*(peek(254)and63)-1+f:pc=pc-(pc<0)*65536:ec=pc
1002 ifec>16383thenec=ec-16384:goto1002
1004 print"pc=";:syshx,pc:print" op=";
1005 syshx,peek(ec+16384):print" a=";:syshx,peek(139):print" x=";
1010 syshx,peek(140):print" y=";:syshx,peek(141):print" p=";
1020 syshx,peek(251):print" s=";:syshx,peek(252):print:return
#-echar
1500 x$="":print"%a4";
1510 geta$:ifa$=""goto1510
1511 ifa$=chr$(20)andlen(x$)>0thenx$=left$(x$,len(x$)-1):goto1540
1520 ifa$=chr$(13)thenprint"{|} {|}":return
1530 iflen(x$)>15goto1510
1532 ifa$<" "ora$>"z"goto1510
1535 x$=x$+a$
1540 print"{|}"a$"%a4 {|}";:goto1510
1600 x$="":print"%a4";
1610 geta$:ifa$=""goto1610
1611 ifa$=chr$(20)andlen(x$)>0thenx$=left$(x$,len(x$)-1):goto1640
1620 ifa$=chr$(13)thenprint"{|} {|}":return
1630 iflen(x$)>3goto1610
1632 if(a$>="0"anda$<="9")or(a$>="a"anda$<="f")goto1635
1633 goto1610
1635 x$=x$+a$
1640 print"{|}"a$"%a4 {|}";:goto1610
1700 v=0
1701 x$=right$("0000"+x$,4):forx=0to3:i=asc(mid$(x$,x+1)):i=i-48:ifi>9theni=i-7
1705 v=v+(4096/16^x)*i:next:return
