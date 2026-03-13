<?php

function send_verification_email(string $toEmail, string $fullName, string $code): void
{
    // Placeholder: utilise mail() simple. À remplacer par PHPMailer / SMTP en prod.
    $subject = 'Vérification de votre compte';
    $message = "Bonjour $fullName,\n\n";
    $message .= "Votre code de vérification est : $code\n";
    $message .= "Ce code expire dans 10 minutes.\n\n";
    $message .= "Merci,\nL'équipe Trouvé!";

    // Suppression des warnings éventuels ; on ignore les erreurs d'envoi pour ne pas bloquer le flux.
    @mail($toEmail, $subject, $message, "Content-Type: text/plain; charset=UTF-8");
}
