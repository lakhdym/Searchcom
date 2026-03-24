<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$vendorAutoload = __DIR__ . '/../vendor/autoload.php';
$mailerAvailable = true;
if (file_exists($vendorAutoload)) {
    require_once $vendorAutoload;
} elseif (
    file_exists(__DIR__ . '/../libs/phpmailer/src/PHPMailer.php') &&
    file_exists(__DIR__ . '/../libs/phpmailer/src/SMTP.php') &&
    file_exists(__DIR__ . '/../libs/phpmailer/src/Exception.php')
) {
    require_once __DIR__ . '/../libs/phpmailer/src/PHPMailer.php';
    require_once __DIR__ . '/../libs/phpmailer/src/SMTP.php';
    require_once __DIR__ . '/../libs/phpmailer/src/Exception.php';
} else {
    $mailerAvailable = false;
}

function sendResetEmail(string $email, string $name, string $token): bool
{
    global $mailerAvailable;
    if (!$mailerAvailable || !class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        $resetLink = "https://italents.ma/app/reset_password?token=" . urlencode($token);
        @mail($email, 'Réinitialisation de votre mot de passe', "Lien: $resetLink");
        return true;
    }

    $mail = new PHPMailer(true);
    try {
        // TODO: remplace par ta config SMTP validée (même que vérif email)
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'YOUR_EMAIL@gmail.com';
        $mail->Password   = 'APP_PASSWORD';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;

        $mail->setFrom('no-reply@italents.ma', 'Trouvé!');
        $mail->addAddress($email, $name);

        $resetLink = "https://italents.ma/app/reset_password?token=" . urlencode($token);

        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = 'Réinitialisation de votre mot de passe';
        $mail->Body = "
            <p>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</p>
            <p>Vous avez demandé à réinitialiser votre mot de passe.</p>
            <p>Utilisez le lien suivant (valide 15 minutes) :</p>
            <p><a href='$resetLink'>$resetLink</a></p>
            <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
            <p>L'équipe Trouvé!</p>
        ";
        $mail->AltBody = "Bonjour $name,\nRéinitialisez votre mot de passe : $resetLink (15 minutes)\nSi ce n'est pas vous, ignorez ce message.\nL'équipe Trouvé!";

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] Reset email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        $resetLink = "https://italents.ma/app/reset_password?token=" . urlencode($token);
        @mail($email, 'Réinitialisation de votre mot de passe', "Lien: $resetLink");
        return false;
    }
}

function sendOtpEmail(string $email, string $name, string $otp): bool
{
    global $mailerAvailable;
    if (!$mailerAvailable || !class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        @mail($email, 'Code de réinitialisation', "Votre code OTP: $otp (valable 10 minutes)");
        return true;
    }

    $mail = new PHPMailer(true);
    try {
        // TODO: remplace par ta config SMTP validée
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'YOUR_EMAIL@gmail.com';
        $mail->Password   = 'APP_PASSWORD';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;

        $mail->setFrom('no-reply@italents.ma', 'Trouvé!');
        $mail->addAddress($email, $name);

        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = 'Code de réinitialisation';
        $mail->Body = "
            <p>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</p>
            <p>Voici votre code de réinitialisation de mot de passe :</p>
            <p style='font-size:22px;font-weight:bold;'>$otp</p>
            <p>Ce code est valable 10 minutes.</p>
            <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
            <p>L'équipe Trouvé!</p>
        ";
        $mail->AltBody = "Code OTP: $otp (valable 10 minutes)";

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] OTP email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        @mail($email, 'Code de réinitialisation', "Votre code OTP: $otp (valable 10 minutes)");
        return false;
    }
}
