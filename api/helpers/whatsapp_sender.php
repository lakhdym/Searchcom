<?php
// Stub d'envoi WhatsApp. À remplacer par l'intégration réelle (Twilio / WhatsApp Cloud API).

function send_whatsapp_otp(string $phone, string $code): bool
{
    // TODO: intégrer l'envoi via votre provider.
    // Ex: appeler Twilio Verify WhatsApp ou WhatsApp Cloud API avec un template d'OTP.
    // Pour l'instant on log simplement.
    error_log("[OTP WhatsApp] $phone -> code $code");
    return true;
}
