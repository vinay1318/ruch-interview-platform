package com.ruch.interviewplatform;

import org.junit.jupiter.api.Test;
import org.testcontainers.mysql.MySQLContainer;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.sql.Connection;
import java.sql.DriverManager;

class MySqlContainerSmokeTest {

    @Test
    void shouldConnectToMySqlContainer() throws Exception {

        try (MySQLContainer mysql =
                     new MySQLContainer("mysql:8.0")
                             .withDatabaseName("ruch_test")) {

            mysql.start();

            try (Connection connection = DriverManager.getConnection(
                    mysql.getJdbcUrl(),
                    mysql.getUsername(),
                    mysql.getPassword())) {

                assertTrue(connection.isValid(5));
            }
        }
    }
}