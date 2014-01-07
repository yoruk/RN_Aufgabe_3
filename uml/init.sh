#!/bin/bash
 
name=$(/usr/bin/awk 'BEGIN {RS=" ";FS="="}$1=="name"{print $2}' /proc/cmdline )
 
echo "Init script on router $name started."
 
hostname $name
 
echo "1" > /proc/sys/net/ipv4/ip_forward
 
echo "#no nameserver configured" >/etc/resolv.conf
 
echo '127.0.0.1 localhost
172.16.11.1 r1_0
172.16.11.2 r2_0
172.16.12.1 r2_1
172.16.15.1 r2_2
172.16.12.2 r3_0
172.16.12.3 r4_0
172.16.103.2 r4_1
172.16.103.1 r5_0
172.16.106.1 r5_1
172.16.207.1 r5_2
172.16.106.2 r6_0
172.16.15.2 r6_1
172.16.14.1 r6_2
172.16.14.2 r7_0
172.16.207.2 r8_0' >/etc/hosts
 
echo ' '>/root/.bash_history
 
 
ifconfig lo 127.0.0.1/24 up
 
 
case $name in
  r1)
    ifconfig eth0 172.16.11.1/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r2_0
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
    
  ;;
  r2)
    ifconfig eth0 172.16.11.2/24 up
    ifconfig eth1 172.16.12.1/24 up
    ifconfig eth2 172.16.15.1/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r6_1
    route add -net 172.16.103.0/24 gw r4_0
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
    
    # policy auf DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP
    
    # ping von r1 und r7 erlauben
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

    # ssh von r1 auf r3 erlauben
    iptables -A FORWARD -p tcp -s r1_0 -d r3_0 --dport 22 -j ACCEPT
    iptables -A FORWARD -p tcp -s r3_0 -d r1_0 --sport 22 -j ACCEPT

    # ssh von r7 auf r3 erlauben
    iptables -A FORWARD -p tcp -s r7_0 -d r3_0 --dport 22 -j ACCEPT
    iptables -A FORWARD -p tcp -s r3_0 -d r7_0 --sport 22 -j ACCEPT

    # stateful firewall - bereits bestehende verbindungen erlauben
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

    #stateful firewall- erstes http-paket erlauben
    iptables -A FORWARD -m state --state NEW -p tcp --dport 80 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben (DATA)
    iptables -A FORWARD -m state --state NEW -p tcp --dport 20 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben  (CONTROL)
    iptables -A FORWARD -m state --state NEW -p tcp --dport 21 --syn -d r3_0 -j ACCEPT
  
  ;;
  r3)
    ifconfig eth0 172.16.12.2/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r2_1
    route add -net 172.16.103.0/24 gw r4_0
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:

   
  ;;
  r4)
    ifconfig eth0 172.16.12.3/24 up
    ifconfig eth1 172.16.103.2/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r2_1
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
    
    # policy auf DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

    # ping von r1 und r7 erlauben, r5 verwerfen
    iptables -A INPUT -p icmp --icmp-type echo-request -s r5_0 -j DROP
    iptables -A FORWARD -p icmp --icmp-type echo-request -s r5_0 -j DROP
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

    # stateful firewall - bereits bestehende verbindungen erlauben
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

    #stateful firewall- erstes http-paket erlauben
    iptables -A FORWARD -m state --state NEW -p tcp --dport 80 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben  (DATA) 
    iptables -A FORWARD -m state --state NEW -p tcp --dport 20 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben  (CONTROL)
    iptables -A FORWARD -m state --state NEW -p tcp --dport 21 --syn -d r3_0 -j ACCEPT


  ;;
  r5)
    ifconfig eth0 172.16.103.1/24 up
    ifconfig eth1 172.16.106.1/24 up
    ifconfig eth2 172.16.207.1/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r4_1
    route add -net 172.16.14.0/24 gw r6_0
    route add -net 172.16.15.0/24 gw r6_0
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
   
  ;;
  r6)
    ifconfig eth0 172.16.106.2/24 up
    ifconfig eth1 172.16.15.2/24 up
    ifconfig eth2 172.16.14.1/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r2_2
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
   
    # policy auf DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP
   
    # ping von r1 und r7 erlauben, r5 verwerfen
    iptables -A INPUT -p icmp --icmp-type echo-request -s r5_1 -j DROP
    iptables -A FORWARD -p icmp --icmp-type echo-request -s r5_1 -j DROP
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

    # ssh von r7 auf r3 erlauben
    iptables -A FORWARD -p tcp -s r7_0 -d r3_0 --dport 22 -j ACCEPT
    iptables -A FORWARD -p tcp -s r3_0 -d r7_0 --sport 22 -j ACCEPT

    # stateful firewall - bereits bestehende verbindungen erlauben
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

    #stateful firewall- erstes http-paket erlauben
    iptables -A FORWARD -m state --state NEW -p tcp --dport 80 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben  (DATA)
    iptables -A FORWARD -m state --state NEW -p tcp --dport 20 --syn -d r3_0 -j ACCEPT

    #stateful firewall- erstes ftp-paket erlauben  (CONTROL)
    iptables -A FORWARD -m state --state NEW -p tcp --dport 21 --syn -d r3_0 -j ACCEPT

    #Network Adress Translation (NAT)
    iptables -t nat -A POSTROUTING -s 172.16.14.0/24 -o eth0 -j MASQUERADE
  
  ;;
  r7)
    ifconfig eth0 172.16.14.2/24 up
    # hier die Routingtabellen einstellen:
    route add default gw r6_2
    # Loesche alle vorhandenen Firewall-Eintraege
    iptables -F
    # hier die iptables-Befehle eintragen:
   
  ;;
# r8)
# ifconfig eth0 172.16.207.2/24 up
# # hier die Routingtabellen einstellen:
 
# # Loesche alle vorhandenen Firewall-Eintraege
# iptables -F
# # hier die iptables-Befehle eintragen:
# ;;
esac
