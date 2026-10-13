const mcpbBridge = r'''
'use strict';

const endpoint = process.argv[2];

let buffered = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffered += chunk;
  let newline;
  while ((newline = buffered.indexOf('\n')) >= 0) {
    const line = buffered.slice(0, newline).trim();
    buffered = buffered.slice(newline + 1);
    if (line) forward(line);
  }
});

function write(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function fail(message, detail) {
  for (const item of [].concat(message)) {
    if (item && item.id != null) {
      write({
        jsonrpc: '2.0',
        id: item.id,
        error: { code: -32603, message: detail },
      });
    }
  }
}

async function forward(line) {
  let message;
  try {
    message = JSON.parse(line);
  } catch {
    write({
      jsonrpc: '2.0',
      id: null,
      error: { code: -32700, message: 'Parse error' },
    });
    return;
  }
  let response;
  try {
    response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        accept: 'application/json, text/event-stream',
      },
      body: JSON.stringify(message),
    });
  } catch (error) {
    fail(message, `cannot reach newtube: ${error.message}`);
    return;
  }
  if (response.status === 202 || response.status === 204) return;
  const type = response.headers.get('content-type') || '';
  const text = await response.text();
  if (type.includes('text/event-stream')) {
    for (const event of text.split(/\r?\n\r?\n/)) {
      for (const row of event.split(/\r?\n/)) {
        if (row.startsWith('data:')) {
          process.stdout.write(`${row.slice(5).trim()}\n`);
        }
      }
    }
    return;
  }
  if (!text) return;
  try {
    for (const item of [].concat(JSON.parse(text))) {
      write(item);
    }
  } catch {
    fail(message, 'invalid response from newtube');
  }
}
''';
