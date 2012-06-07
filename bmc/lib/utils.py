#!/usr/bin/env python
"""
General Utilities
(part of bmc)
"""

import sys
import os
import itertools
import logging
import smtplib
import email.Utils

__all__ = [
  "Storage", "storage",  
  "safestr",
  "sendmail"
]

class Storage(dict):
    """
    A Storage object is like a dictionary except `obj.foo` can be used
    in addition to `obj['foo']`.
    
        >>> o = storage(a=1)
        >>> o.a
        1
        >>> o['a']
        1
        >>> o.a = 2
        >>> o['a']
        2
        >>> del o.a
        >>> o.a
        Traceback (most recent call last):
            ...
        AttributeError: 'a'
    
    """
    def __getattr__(self, key): 
        try:
            return self[key]
        except KeyError, k:
            raise AttributeError, k
    
    def __setattr__(self, key, value): 
        self[key] = value
    
    def __delattr__(self, key):
        try:
            del self[key]
        except KeyError, k:
            raise AttributeError, k
    
    def __repr__(self):     
        return '<Storage ' + dict.__repr__(self) + '>'

storage = Storage

def safestr(obj, encoding='utf-8'):
    r"""
    Converts any given object to utf-8 encoded string. 
    
        >>> safestr('hello')
        'hello'
        >>> safestr(u'\u1234')
        '\xe1\x88\xb4'
        >>> safestr(2)
        '2'
    """
    if isinstance(obj, unicode):
        return obj.encode('utf-8')
    elif isinstance(obj, str):
        return obj
    elif hasattr(obj, 'next') and hasattr(obj, '__iter__'): # iterator
        return itertools.imap(safestr, obj)
    else:
        return str(obj)
		
def sendmail(from_address, to_address, subject, message, headers=None, **kw):
    """
    Sends the email message `message` with mail and envelope headers
    for from `from_address_` to `to_address` with `subject`. 
    Additional email headers can be specified with the dictionary 
    `headers.
    
    Optionally cc, bcc and attachments can be specified as keyword arguments.
    Attachments must be an iterable and each attachment can be either a 
    filename or a file object or a dictionary with filename, content and 
    optionally content_type keys.

    If `web.config.smtp_server` is set, it will send the message
    to that SMTP server. Otherwise it will look for 
    `/usr/sbin/sendmail`, the typical location for the sendmail-style
    binary. To use sendmail from a different path, set `web.config.sendmail_path`.
    """
    attachments = kw.pop("attachments", [])
    mail = _EmailMessage(from_address, to_address, subject, message, headers, **kw)

    for a in attachments:
        if isinstance(a, dict):
            mail.attach(a['filename'], a['content'], a.get('content_type'))
        elif hasattr(a, 'read'): # file
            filename = os.path.basename(getattr(a, "name", ""))
            content_type = getattr(a, 'content_type', None)
            mail.attach(filename, a.read(), content_type)
        elif isinstance(a, basestring):
            f = open(a, 'rb')
            content = f.read()
            f.close()
            filename = os.path.basename(a)
            mail.attach(filename, content, None)
        else:
            raise ValueError, "Invalid attachment: %s" % repr(a)
            
    mail.send()
		
class _EmailMessage:
    def __init__(self, from_address, to_address, subject, message, headers=None, **kw):
        def listify(x):
            if not isinstance(x, list):
                return [safestr(x)]
            else:
                return [safestr(a) for a in x]
    
        subject = safestr(subject)
        message = safestr(message)

        from_address = safestr(from_address)
        to_address = listify(to_address)    
        cc = listify(kw.get('cc', []))
        bcc = listify(kw.get('bcc', []))
        recipients = to_address + cc + bcc

        self.from_address = email.Utils.parseaddr(from_address)[1]
        self.recipients = [email.Utils.parseaddr(r)[1] for r in recipients]        
    
        self.headers = dictadd({
          'From': from_address,
          'To': ", ".join(to_address),
          'Subject': subject
        }, headers or {})

        if cc:
            self.headers['Cc'] = ", ".join(cc)
    
        self.message = self.new_message()
        self.message.add_header("Content-Transfer-Encoding", "7bit")
        self.message.add_header("Content-Disposition", "inline")
        self.message.add_header("MIME-Version", "1.0")
        self.message.set_payload(message, 'utf-8')
        self.multipart = False
        
    def new_message(self):
        from email.Message import Message
        return Message()
        
    def attach(self, filename, content, content_type=None):
        if not self.multipart:
            msg = self.new_message()
            msg.add_header("Content-Type", "multipart/mixed")
            msg.attach(self.message)
            self.message = msg
            self.multipart = True
                        
        import mimetypes
        try:
            from email import encoders
        except:
            from email import Encoders as encoders
            
        content_type = content_type or mimetypes.guess_type(filename)[0] or "applcation/octet-stream"
        
        msg = self.new_message()
        msg.set_payload(content)
        msg.add_header('Content-Type', content_type)
        msg.add_header('Content-Disposition', 'attachment', filename=filename)
        
        if not content_type.startswith("text/"):
            encoders.encode_base64(msg)
            
        self.message.attach(msg)
    
    def send(self):
        try:
            import bmcapi
        except ImportError:
            bmcapi = Storage(config=Storage())
            
        for k, v in self.headers.iteritems():
            self.message.add_header(k, v)
            
        message_text = self.message.as_string()
    
        if bmcapi.config.get('SMTP_SERVER'):
            server = bmcapi.config.get('SMTP_SERVER')
            port = bmcapi.config.get('smtp_port', 0)
            username = bmcapi.config.get('smtp_username') 
            password = bmcapi.config.get('smtp_password')
            debug_level = bmcapi.config.get('smtp_debuglevel', None)
            starttls = bmcapi.config.get('smtp_starttls', False)

            smtpserver = smtplib.SMTP(server, port)

            if debug_level:
                smtpserver.set_debuglevel(debug_level)

            if starttls:
                smtpserver.ehlo()
                smtpserver.starttls()
                smtpserver.ehlo()

            if username and password:
                smtpserver.login(username, password)

            smtpserver.sendmail(self.from_address, self.recipients, message_text)
            smtpserver.quit()
        else:
            sendmail = bmcapi.config.get('sendmail_path', '/usr/sbin/sendmail')
        
            assert not self.from_address.startswith('-'), 'security'
            for r in self.recipients:
                assert not r.startswith('-'), 'security'
                
            cmd = [sendmail, '-f', self.from_address] + self.recipients

            if subprocess:
                p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
                p.stdin.write(message_text)
                p.stdin.close()
                p.wait()
            else:
                i, o = os.popen2(cmd)
                i.write(message)
                i.close()
                o.close()
                del i, o
                
    def __repr__(self):
        return "<EmailMessage>"
    
    def __str__(self):
        return self.message.as_string()
		
