#!/usr/bin/env node

/**
 * Telegram Authentication API Test Script
 * This script tests the backend authentication endpoints
 * Run with: node test_telegram_auth.js
 */

const https = require('https');
const http = require('http');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 5000
};

// Colors for console output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// HTTP request helper
function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const protocol = options.hostname === 'localhost' ? http : https;
    
    const req = protocol.request(options, (res) => {
      let body = '';
      
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonBody = JSON.parse(body);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: jsonBody
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: body
          });
        }
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.setTimeout(config.timeout, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Parse URL for request options
function parseUrl(url) {
  const urlObj = new URL(url);
  return {
    hostname: urlObj.hostname,
    port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
    path: urlObj.pathname + urlObj.search,
    protocol: urlObj.protocol
  };
}

// Test 1: Health Check
async function testHealthCheck() {
  log('\n=== Test 1: Health Check ===', 'blue');
  
  try {
    const urlOptions = parseUrl(`${config.baseUrl}/health`);
    const options = {
      ...urlOptions,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const response = await makeRequest(options);
    
    if (response.statusCode === 200) {
      log('✅ Health check passed', 'green');
      log(`Response: ${JSON.stringify(response.body, null, 2)}`);
      return true;
    } else {
      log(`❌ Health check failed with status ${response.statusCode}`, 'red');
      return false;
    }
  } catch (error) {
    log(`❌ Health check error: ${error.message}`, 'red');
    return false;
  }
}

// Test 2: Start Telegram Auth
async function testStartTelegramAuth() {
  log('\n=== Test 2: Start Telegram Authentication ===', 'blue');
  
  try {
    const urlOptions = parseUrl(`${config.baseUrl}/auth/telegram/start`);
    const options = {
      ...urlOptions,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const response = await makeRequest(options);
    
    if (response.statusCode === 200 && response.body.token && response.body.url) {
      log('✅ Telegram auth start successful', 'green');
      log(`Token: ${response.body.token}`);
      log(`URL: ${response.body.url}`);
      
      // Validate token format (should be 32 hex characters)
      if (/^[a-f0-9]{32}$/.test(response.body.token)) {
        log('✅ Token format is valid (32 hex characters)', 'green');
      } else {
        log('❌ Token format is invalid', 'red');
      }
      
      // Validate URL format
      if (response.body.url.startsWith('https://t.me/') && response.body.url.includes('start=token_')) {
        log('✅ URL format is valid', 'green');
      } else {
        log('❌ URL format is invalid', 'red');
      }
      
      return response.body.token;
    } else {
      log(`❌ Telegram auth start failed with status ${response.statusCode}`, 'red');
      log(`Response: ${JSON.stringify(response.body, null, 2)}`);
      return null;
    }
  } catch (error) {
    log(`❌ Telegram auth start error: ${error.message}`, 'red');
    return null;
  }
}

// Test 3: Check Token Status
async function testTokenStatus(token) {
  log('\n=== Test 3: Check Token Status ===', 'blue');
  
  if (!token) {
    log('❌ No token provided', 'red');
    return false;
  }
  
  try {
    const urlOptions = parseUrl(`${config.baseUrl}/auth/telegram/status/${token}`);
    const options = {
      ...urlOptions,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const response = await makeRequest(options);
    
    if (response.statusCode === 200) {
      log('✅ Token status check successful', 'green');
      log(`Status: ${response.body.status}`);
      
      if (response.body.status === 'pending') {
        log('✅ Token is in pending state (expected for new token)', 'green');
      } else if (response.body.status === 'confirmed') {
        log('✅ Token is confirmed', 'green');
        if (response.body.telegram_id) {
          log(`Telegram ID: ${response.body.telegram_id}`);
        }
      }
      
      return true;
    } else {
      log(`❌ Token status check failed with status ${response.statusCode}`, 'red');
      return false;
    }
  } catch (error) {
    log(`❌ Token status check error: ${error.message}`, 'red');
    return false;
  }
}

// Test 4: Database Connection
async function testDatabaseConnection() {
  log('\n=== Test 4: Database Connection ===', 'blue');
  
  try {
    const urlOptions = parseUrl(`${config.baseUrl}/test-db`);
    const options = {
      ...urlOptions,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const response = await makeRequest(options);
    
    if (response.statusCode === 200 && response.body.success) {
      log('✅ Database connection successful', 'green');
      log(`Database time: ${JSON.stringify(response.body.time)}`);
      return true;
    } else {
      log(`❌ Database connection failed`, 'red');
      log(`Response: ${JSON.stringify(response.body, null, 2)}`);
      return false;
    }
  } catch (error) {
    log(`❌ Database connection error: ${error.message}`, 'red');
    return false;
  }
}

// Test 5: User Profile (Mock Test)
async function testUserProfile() {
  log('\n=== Test 5: User Profile Endpoint ===', 'blue');
  
  // Use a test telegram ID (this will likely return 404, which is expected)
  const testTelegramId = '123456789';
  
  try {
    const urlOptions = parseUrl(`${config.baseUrl}/user/${testTelegramId}`);
    const options = {
      ...urlOptions,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const response = await makeRequest(options);
    
    if (response.statusCode === 404) {
      log('✅ User profile endpoint working (404 expected for non-existent user)', 'green');
      return true;
    } else if (response.statusCode === 200) {
      log('✅ User profile found', 'green');
      log(`User data: ${JSON.stringify(response.body, null, 2)}`);
      return true;
    } else {
      log(`❌ User profile endpoint error with status ${response.statusCode}`, 'red');
      return false;
    }
  } catch (error) {
    log(`❌ User profile endpoint error: ${error.message}`, 'red');
    return false;
  }
}

// Main test runner
async function runAllTests() {
  log('🚀 Starting Telegram Authentication API Tests', 'blue');
  log(`Testing against: ${config.baseUrl}`, 'yellow');
  
  const results = {
    passed: 0,
    failed: 0,
    total: 5
  };
  
  // Run tests
  const tests = [
    { name: 'Health Check', fn: testHealthCheck },
    { name: 'Database Connection', fn: testDatabaseConnection },
    { name: 'Start Telegram Auth', fn: testStartTelegramAuth },
    { name: 'Token Status', fn: null }, // Will be run with token from previous test
    { name: 'User Profile', fn: testUserProfile }
  ];
  
  let authToken = null;
  
  for (let i = 0; i < tests.length; i++) {
    const test = tests[i];
    let result = false;
    
    if (test.name === 'Start Telegram Auth') {
      authToken = await test.fn();
      result = authToken !== null;
    } else if (test.name === 'Token Status') {
      result = await testTokenStatus(authToken);
    } else if (test.fn) {
      result = await test.fn();
    }
    
    if (result) {
      results.passed++;
    } else {
      results.failed++;
    }
  }
  
  // Print summary
  log('\n=== Test Summary ===', 'blue');
  log(`Total tests: ${results.total}`);
  log(`Passed: ${results.passed}`, results.passed > 0 ? 'green' : 'reset');
  log(`Failed: ${results.failed}`, results.failed > 0 ? 'red' : 'reset');
  
  if (results.failed === 0) {
    log('\n🎉 All tests passed!', 'green');
  } else {
    log('\n⚠️ Some tests failed. Check the configuration and server status.', 'yellow');
  }
  
  // Additional notes
  log('\n📝 Notes:', 'blue');
  log('- To test the complete login flow, use a real device with Telegram app');
  log('- Configure the TELEGRAM_BOT_TOKEN in your .env file for full functionality');
  log('- The token status will remain "pending" until confirmed via Telegram bot');
  
  if (authToken) {
    log(`\n🔑 Generated auth token for manual testing: ${authToken}`, 'yellow');
    log(`Test URL: https://t.me/SportBuddyAuthBot?start=token_${authToken}`);
  }
}

// Run the tests
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  runAllTests,
  testHealthCheck,
  testStartTelegramAuth,
  testTokenStatus,
  testDatabaseConnection,
  testUserProfile
};
