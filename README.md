# (Ararat) Synapse TCP/IP library for Pascal (+websocket support)
Official source repository is https://github.com/geby/synapse (It was changed from SourceForge at January 2024)
 
### Compatibility
* **Delphi 5 - 2007** (ANSI, Win32)
* **Delphi 2009 - 12** (Unicode, Win32/Win64/Android)
* **FreePascal** (Win32/Win64, probably all platforms supported by **sockets** unit)

### Basic features
* IPv4 and IPv6 support
* low level UDP protocol, include SOCKS5 proxy support
* low level TCP protocol, include SOCKS4/5 or HTTP proxy support, TLS encryption by 3rd-party libraries (OpenSSL 3.x, etc.)
* ICMP pings
* Basic support for internet protocols like: DNS, SMTP, IMAP4, HTTP, NTP, POP3, FTP, TFTP, SNMP, LDAP, Syslog, NNTP, Telnet, ClamD 
* encoding/decoding MIME messages, include charset conversions. Old style UUcode, XXcode and Yenc supported too
* many handy utilities included
* Serial port communication, include high-speed USB chips

### Support
Feel free to use:
* Read the [wiki](https://github.com/geby/synapse/wiki)
* Ask in [discussions](https://github.com/geby/synapse/discussions)
* Report [issues](https://github.com/geby/synapse/issues)

### BSD style license
**Copyright (c)1999-2024, Lukas Gebauer**
**All rights reserved.**

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Lukas Gebauer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

<sub>Version: 2024/01/16</sub>
