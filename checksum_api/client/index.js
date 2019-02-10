const fs = require('fs');
const readline = require('readline');
const stream = require('stream');
const axios = require('axios');
const minimist = require('minimist');

const headers = { Accept: 'application/vnd.checksum.v1+json' };

async function processCommands(inputFilePath, port) {
  const commands = fs.readFileSync(inputFilePath, 'utf-8').split('\n');
  let result = '';
  for (const command of commands) {
    if (command.startsWith('A')) {
      const number = command.substring(1);
      if (RegExp('^[0-9]+$').test(number)) {
        await add(number, port);
      }
    } else if (command === 'CS') {
      result += await checksum(port);
    } else if (command === 'C') {
      await clear(port);
    }
  }
  return result;
}

async function add(number, port) {
  await axios({
    method: 'post',
    url: uri(port, '/numbers'),
    params: { number },
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}

async function checksum(port) {
  const response = await axios({
    method: 'get',
    url: uri(port, '/numbers/checksum'),
    headers,
  });
  return response.data.checksum;
}

async function clear(port) {
  await axios({
    method: 'delete',
    url: uri(port, '/numbers'),
    headers,
  });
}

function uri(port, path) {
  return `http://localhost:${port}${path}`;
}

function validateArguments(argv) {
  let { input, port } = argv;
  port = Number(port);

  if (!input || typeof input !== 'string') {
    throw new Error("mandatory 'input' argument missing.");
  } else if (!Number.isInteger(port) || port < 0) {
    throw new Error(
      "mandatory 'port' argument is missing or is not a valid port number."
    );
  }

  return { input, port };
}

const argv = minimist(process.argv.slice(2));
const { input, port } = validateArguments(argv);
(async () => {
  const result = await processCommands(input, port);
  console.log(`\n\nConcatenated checksums:\n${result}\n\n`);
})();
