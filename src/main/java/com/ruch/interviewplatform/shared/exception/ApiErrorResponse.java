package com.ruch.interviewplatform.shared.exception;

import org.springframework.cglib.core.Local;

import java.time.LocalDateTime;

public record ApiErrorResponse(
        LocalDateTime timestamp,
        int status,
        String error,
        String message,
        String path,
        String requestId
) {
}
