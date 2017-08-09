#!/usr/bin/env node
const fs = require('fs');
const objectiveCParser = require('objective-c-parser');
const t = require('babel-types');
const generate = require('babel-generator').default;

const files = {
    './detox/ios/EarlGrey/EarlGrey/Action/GREYActions.h': './demo.js',
};

Object.entries(files).forEach(([inputFile, outputFile]) => {
    const input = fs.readFileSync(inputFile, 'utf8');
    const json = objectiveCParser(input);
    const ast = createClass(json);
    const output = generate(ast);

    fs.writeFileSync(outputFile, output.code, 'utf8');
});

function createClass(json) {
    return t.classDeclaration(t.identifier(json.name), null, t.classBody(json.methods.map(createMethod)), []);
}

function createMethod(json) {
    return t.classMethod("method", t.identifier(json.name.replace(/\:/g, '')), json.args.map(createArgument), t.blockStatement([]), false, true);
}

function createArgument(json) {
    return t.identifier(json.name);
}