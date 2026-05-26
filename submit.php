<?php
/**
 * submit.php — MedCare contact form handler
 * ICT171 Assignment 3 — Allan Kibiwott
 *
 * Validates and logs form submissions to a server-side log file.
 * Demonstrates PHP server-side processing on Apache2.
 */

// Input validation
$errors = [];

$name    = isset($_POST['name'])    ? trim(htmlspecialchars($_POST['name']))    : '';
$email   = isset($_POST['email'])   ? trim(htmlspecialchars($_POST['email']))   : '';
$subject = isset($_POST['subject']) ? trim(htmlspecialchars($_POST['subject'])) : '';
$message = isset($_POST['message']) ? trim(htmlspecialchars($_POST['message'])) : '';

if (empty($name))              $errors[] = "Name is required.";
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = "Valid email is required.";
if (empty($subject))           $errors[] = "Subject is required.";
if (strlen($message) < 10)    $errors[] = "Message must be at least 10 characters.";

if (empty($errors)) {
    // Log submission to file (verifiable output — server-side)
    $log_file = '/var/log/medcare_contacts.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] Name: $name | Email: $email | Subject: $subject | Msg: " . substr($message, 0, 80) . "\n";
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

    // Success response
    $success = true;
} else {
    $success = false;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?php echo $success ? 'Message Sent' : 'Error'; ?> — MedCare</title>
  <link rel="stylesheet" href="style.css">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
  <nav class="navbar">
    <div class="container nav-inner">
      <a href="index.html" class="logo"><span class="logo-icon">&#x2764;</span> MedCare</a>
    </div>
  </nav>

  <section class="section" style="min-height:60vh; display:flex; align-items:center;">
    <div class="container" style="text-align:center; max-width:560px; margin:0 auto;">
      <?php if ($success): ?>
        <div style="font-size:4rem;">&#10003;</div>
        <h2 style="color:#1a7a4a; margin-top:1rem;">Message Sent!</h2>
        <p>Thank you, <strong><?php echo $name; ?></strong>. Your message has been received and logged on the server. We'll respond to <strong><?php echo $email; ?></strong> within 24 hours.</p>
        <a href="index.html" class="btn btn-primary" style="margin-top:2rem;">Back to Home</a>
      <?php else: ?>
        <div style="font-size:4rem;">&#10007;</div>
        <h2 style="color:#c0392b; margin-top:1rem;">Please Fix These Errors</h2>
        <ul style="text-align:left; margin:1.5rem auto; max-width:360px;">
          <?php foreach ($errors as $e): ?>
            <li style="margin-bottom:0.5rem; color:#c0392b;"><?php echo $e; ?></li>
          <?php endforeach; ?>
        </ul>
        <a href="contact.html" class="btn btn-primary">Go Back</a>
      <?php endif; ?>
    </div>
  </section>

  <footer class="footer">
    <div class="container footer-inner">
      <div><span class="logo">&#x2764; MedCare</span></div>
      <div><p>allankibiwott.net &bull; ICT171 Murdoch University</p></div>
    </div>
  </footer>
</body>
</html>
