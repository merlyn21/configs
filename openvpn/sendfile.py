#!/usr/bin/env python -w
# coding: utf-8

import smtplib
import os
import sys
import subprocess
import email
from email import encoders
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.utils import formatdate


def send2mail(addr, subj, file_to_attach="none"):
    msg = MIMEMultipart()

    address = addr

    msg['From'] = 'mail@from'
    msg['To'] = addr
    msg['Subject'] = subj

    f = open('message.txt', encoding='utf-8')

    message = email.message_from_file(f)

    msg.attach(message)

    if file_to_attach != "none":
        ind = file_to_attach.rfind("/")
        name_file_to_attach = file_to_attach[ind+1:len(file_to_attach)]
        header = 'Content-Disposition', 'attachment; filename="%s"' % name_file_to_attach

    attachment = MIMEBase('application', "octet-stream")

    if file_to_attach != "none":
        try:
            with open(file_to_attach, "rb") as fh:
                data = fh.read()

            attachment.set_payload( data )
            encoders.encode_base64(attachment)
            attachment.add_header(*header)
            msg.attach(attachment)
        except IOError:
            msg = "Error opening attachment file %s" % file_to_attach
            print(msg)
            sys.exit(1)


    try:
        mailserver = smtplib.SMTP_SSL('smtp.mail:465')
        mailserver.login('email_from@email', 'pass')
        mailserver.sendmail('email_from@email', address, msg.as_string())
    except Exception as e:
        print(e)
    finally:
        mailserver.quit()


send2mail(sys.argv[1], 'openvpn', sys.argv[2])
