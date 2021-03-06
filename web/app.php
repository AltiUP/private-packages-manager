<?php

use Symfony\Component\HttpFoundation\Request;

/**
 * @var \Symfony\Component\ClassLoader\ClassLoader
 */
$loader = require __DIR__.'/../app/autoload.php';
$kernel = new AppKernel('prod', false);

if (PHP_VERSION_ID < 70100) {
    if (in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1'], true)) {
        Request::setTrustedProxies([$_SERVER['REMOTE_ADDR']]);
        // force all trusted header names
        Request::setTrustedHeaderName(Request::HEADER_FORWARDED, '');
        Request::setTrustedHeaderName(Request::HEADER_CLIENT_IP, 'X_REAL_IP');
        Request::setTrustedHeaderName(Request::HEADER_CLIENT_HOST, '');
        Request::setTrustedHeaderName(Request::HEADER_CLIENT_PROTO, '');
        Request::setTrustedHeaderName(Request::HEADER_CLIENT_PORT, '');
    }
} else {
    Request::setTrustedProxies(
        // remote_addr is set to the correct client IP but we need to mark it trusted so that Symfony picks up the X-Forwarded-Host,
        // X-Forwarded-Port and X-Forwarded-Proto headers correctly and sees the right request URL
        [$_SERVER['REMOTE_ADDR']],
        // Use all X-Forwarded-* headers except X-Forwarded-For as nginx handles the IP computation
        Request::HEADER_X_FORWARDED_AWS_ELB ^ Request::HEADER_X_FORWARDED_FOR
    );
}

$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);
