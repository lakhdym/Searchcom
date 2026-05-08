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

function send_mail_fallback(string $to, string $subject, string $html, string $text): bool
{
    $headers = "MIME-Version: 1.0\r\n" .
               "Content-type: text/html; charset=UTF-8\r\n" .
               "From: Trouvé! <no-reply@italents.ma>\r\n";
    return @mail($to, $subject, $html, $headers);
}

function sendResetEmail(string $email, string $name, string $token): bool
{
    global $mailerAvailable;
    $resetLink = "https://italents.ma/app/reset_password?token=" . urlencode($token);

    $html = "
        <html><body style='margin:0;padding:0;background:#f5f7fb;font-family:Arial,sans-serif;color:#111827;'>
          <table role='presentation' width='100%' cellpadding='0' cellspacing='0' style='background:#f5f7fb;padding:24px 0;'>
            <tr>
              <td align='center'>
                <table role='presentation' width='540' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:12px;padding:32px;box-shadow:0 6px 24px rgba(17,24,39,0.08);'>
                  <tr><td style='font-size:14px;color:#6c7393;text-transform:uppercase;letter-spacing:1px;'>Trouvé!</td></tr>
                  <tr><td style='font-size:20px;font-weight:700;padding:12px 0 6px;'>Réinitialiser votre mot de passe</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;'>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;padding-top:6px;'>Vous avez demandé à réinitialiser votre mot de passe. Cliquez sur le bouton ci-dessous (valide 15 minutes) :</td></tr>
                  <tr><td align='center' style='padding:22px 0;'>
                    <a href='$resetLink' style='background:#6c4bff;color:#ffffff;text-decoration:none;padding:12px 22px;border-radius:8px;font-weight:700;display:inline-block;'>Choisir un nouveau mot de passe</a>
                  </td></tr>
                  <tr><td style='font-size:13px;line-height:1.5;color:#6b7280;word-break:break-all;'>Ou copiez ce lien dans votre navigateur :<br><a href='$resetLink' style='color:#6c4bff;text-decoration:none;'>$resetLink</a></td></tr>
                  <tr><td style='font-size:13px;line-height:1.5;color:#9ca3af;padding-top:18px;'>Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet email.</td></tr>
                </table>
                <div style='font-size:12px;color:#9ca3af;padding-top:12px;'>Trouvé! — italents.ma</div>
              </td>
            </tr>
          </table>
        </body></html>
    ";
    $alt = "Bonjour $name,\n\nRéinitialisez votre mot de passe : $resetLink (valide 15 minutes).\nSi ce n'est pas vous, ignorez ce message.\nTrouvé! / italents.ma";

    if (!$mailerAvailable || !class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        return send_mail_fallback($email, 'Réinitialisation de votre mot de passe', $html, $alt);
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

        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = 'Réinitialisation de votre mot de passe';
        $mail->Body    = $html;
        $mail->AltBody = $alt;

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] Reset email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        return send_mail_fallback($email, 'Réinitialisation de votre mot de passe', $html, $alt);
    }
}

function sendOtpEmail(string $email, string $name, string $otp): bool
{
    global $mailerAvailable;

    $html = "
        <html><body style='margin:0;padding:0;background:#f5f7fb;font-family:Arial,sans-serif;color:#111827;'>
          <table role='presentation' width='100%' cellpadding='0' cellspacing='0' style='background:#f5f7fb;padding:24px 0;'>
            <tr>
              <td align='center'>
                <table role='presentation' width='420' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:12px;padding:28px;box-shadow:0 6px 24px rgba(17,24,39,0.08);'>
                  <tr><td style='font-size:14px;color:#6c7393;text-transform:uppercase;letter-spacing:1px;'>Trouvé!</td></tr>
                  <tr><td style='font-size:20px;font-weight:700;padding:10px 0 6px;'>Votre code de sécurité</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;'>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;padding-top:6px;'>Voici votre code pour réinitialiser votre mot de passe (valide 10 minutes) :</td></tr>
                  <tr><td align='center' style='padding:18px 0;'>
                    <div style='font-size:28px;font-weight:800;letter-spacing:3px;color:#6c4bff;'>$otp</div>
                  </td></tr>
                  <tr><td style='font-size:13px;line-height:1.5;color:#9ca3af;'>Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.</td></tr>
                </table>
                <div style='font-size:12px;color:#9ca3af;padding-top:12px;'>Trouvé! — italents.ma</div>
              </td>
            </tr>
          </table>
        </body></html>
    ";
    $alt = "Votre code: $otp (valable 10 minutes). Si ce n'est pas vous, ignorez ce message. - Trouvé!";

    if (!$mailerAvailable || !class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        return send_mail_fallback($email, 'Code de réinitialisation', $html, $alt);
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
        $mail->Body    = $html;
        $mail->AltBody = $alt;

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] OTP email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        return send_mail_fallback($email, 'Code de réinitialisation', $html, $alt);
    }
}
