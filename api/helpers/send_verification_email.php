<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Charge PHPMailer (Composer ou fallback manuel)
$vendorAutoload = __DIR__ . '/../vendor/autoload.php';
if (file_exists($vendorAutoload)) {
    require_once $vendorAutoload;
} else {
    // Fallback minimal si PHPMailer est placé manuellement dans api/libs/phpmailer
    require_once __DIR__ . '/../libs/phpmailer/src/PHPMailer.php';
    require_once __DIR__ . '/../libs/phpmailer/src/SMTP.php';
    require_once __DIR__ . '/../libs/phpmailer/src/Exception.php';
}

/**
 * Envoie l'email de vérification (OTP 6 chiffres) via SMTP.
 *
 * @return bool true si envoyé, false sinon
 */
function sendVerificationEmail(string $email, string $name, string $code): bool
{
    $mail = new PHPMailer(true);

    try {
        // --- Config SMTP à adapter à ton serveur ---
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';          // hôte SMTP
        $mail->SMTPAuth   = true;
        $mail->Username   = 'YOUR_EMAIL@gmail.com';    // identifiant SMTP
        $mail->Password   = 'APP_PASSWORD';            // mot de passe / app password
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;

        // Expéditeur / Destinataire
        $mail->setFrom('no-reply@italents.ma', 'Trouvé!');
        $mail->addAddress($email, $name);

        // Contenu
        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = 'Verification de votre compte';
        $mail->Body = "
            <p>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</p>
            <p>Votre code de vérification est :</p>
            <h2 style='letter-spacing:4px;'>$code</h2>
            <p>Ce code expire dans 10 minutes.</p>
            <p>Merci,<br>L'équipe Trouvé!</p>
        ";
        $mail->AltBody = "Bonjour $name,\nVotre code de vérification est : $code\nCe code expire dans 10 minutes.\n\nL'équipe Trouvé!";

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] Email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        return false;
    }
}
