module.exports = {
    compileCommand: 'npm run compile -- --all',
    testCommand: 'export PORT=8555&& npm run test -- --network coverage --timeout 100000',
    copyPackages: ['openzeppelin-solidity'],
}