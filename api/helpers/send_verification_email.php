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

function send_mail_verif_fallback(string $to, string $subject, string $html, string $text): bool
{
    $headers = "MIME-Version: 1.0\r\n" .
               "Content-type: text/html; charset=UTF-8\r\n" .
               "From: Trouvé! <no-reply@italents.ma>\r\n";
    $ok = @mail($to, $subject, $html, $headers);
    if (!$ok) {
        error_log('['.date('Y-m-d H:i:s')."] mail() fallback failed for $to\n", 3, __DIR__.'/../api_error.log');
    }
    return $ok;
}

function sendVerificationEmail(string $email, string $name, string $code): bool
{
    global $mailerAvailable;

    $html = "
        <html><body style='margin:0;padding:0;background:#f5f7fb;font-family:Arial,sans-serif;color:#111827;'>
          <table role='presentation' width='100%' cellpadding='0' cellspacing='0' style='background:#f5f7fb;padding:24px 0;'>
            <tr>
              <td align='center'>
                <table role='presentation' width='480' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:12px;padding:28px;box-shadow:0 6px 24px rgba(17,24,39,0.08);'>
                  <tr><td style='font-size:14px;color:#6c7393;text-transform:uppercase;letter-spacing:1px;'>Trouvé!</td></tr>
                  <tr><td style='font-size:20px;font-weight:700;padding:12px 0 6px;'>Vérification de votre compte</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;'>Bonjour <strong>" . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</strong>,</td></tr>
                  <tr><td style='font-size:14px;line-height:1.6;color:#4b5563;padding-top:6px;'>Voici votre code pour valider votre compte (valide 10 minutes) :</td></tr>
                  <tr><td align='center' style='padding:18px 0;'>
                    <div style='font-size:28px;font-weight:800;letter-spacing:3px;color:#6c4bff;'>$code</div>
                  </td></tr>
                  <tr><td style='font-size:13px;line-height:1.5;color:#9ca3af;'>Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.</td></tr>
                </table>
                <div style='font-size:12px;color:#9ca3af;padding-top:12px;'>Trouvé! — italents.ma</div>
              </td>
            </tr>
          </table>
        </body></html>
    ";
    $alt = "Bonjour $name,\nVotre code de vérification est : $code (valide 10 minutes).\nSi ce n'est pas vous, ignorez ce message.\nTrouvé! / italents.ma";

    if (!$mailerAvailable || !class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        return send_mail_verif_fallback($email, 'Vérification de votre compte', $html, $alt);
    }

    $mail = new PHPMailer(true);
    try {
        // TODO: config SMTP à adapter
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
        $mail->Subject = 'Vérification de votre compte';
        $mail->Body    = $html;
        $mail->AltBody = $alt;

        $mail->send();
        return true;
    } catch (Exception $e) {
        $logMsg = '[' . date('Y-m-d H:i:s') . "] Verif email error to $email : " . $mail->ErrorInfo . PHP_EOL;
        error_log($logMsg, 3, __DIR__ . '/../api_error.log');
        return send_mail_verif_fallback($email, 'Vérification de votre compte', $html, $alt);
    }
}
