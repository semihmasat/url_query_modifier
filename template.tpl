___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "URL Query Modifier",
  "description": "Custom variable to modify query parameters of given URL.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "url",
    "displayName": "URL",
    "simpleValueType": true
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "modification_table",
    "displayName": "Modifications",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Query Parameter",
        "name": "query_name",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Modification",
        "name": "modification",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "remove",
            "displayValue": "Remove"
          },
          {
            "value": "downcase",
            "displayValue": "Downcase"
          },
          {
            "value": "upcase",
            "displayValue": "Upcase"
          }
        ]
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "Extras",
    "displayName": "Extras",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "remove_except_first",
        "checkboxText": "Remove Duplicate Parameters",
        "simpleValueType": true,
        "help": "Removes the duplicated query parameters and keeps the first one only."
      },
      {
        "type": "SELECT",
        "name": "keep_which",
        "displayName": "Keep",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "first",
            "displayValue": "First Occurrence"
          },
          {
            "value": "last",
            "displayValue": "Last Occurrence"
          }
        ],
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "remove_except_first",
            "paramValue": true,
            "type": "EQUALS"
          }
        ]
      },
      {
        "type": "CHECKBOX",
        "name": "bare_param_removal",
        "checkboxText": "Remove Bare Parameters",
        "simpleValueType": true,
        "help": "Remove parameters without a value."
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "settings",
    "displayName": "Settings",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "debug_mode",
        "checkboxText": "Enable Debugging",
        "simpleValueType": true,
        "help": "Enables debug logs."
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const decodeUriComponent = require('decodeUriComponent');
const encodeUriComponent = require('encodeUriComponent');
const log = require('logToConsole');

var url = data.url;
var modificationTable = data.modification_table;
var debugMode = data.debug_mode;
var removeExceptOne = data.remove_except_first;
var keepWhich = data.keep_which;
var bareParamRemoval = data.bare_param_removal;
var hasError = false;

function debugLog(message) {
  if (debugMode) {
    log(message);
  }
}

function logError(message) {
  hasError = true;
  log('Error: ' + message);
}

function isArray(value) {
  return value && typeof value === 'object' && typeof value.length === 'number';
}

function stringifyObject(obj) {
  var result = '{';
  for (var key in obj) {
    if (obj.hasOwnProperty(key)) {
      if (result !== '{') result += ', ';
      result += key + ': ' + (isArray(obj[key]) ? '[' + obj[key].join(', ') + ']' : obj[key]);
    }
  }
  result += '}';
  return result;
}

function getQueryParams(url) {
  var params = {};
  var queryString = url.split('?')[1];
  if (queryString) {
    var pairs = queryString.split('&');
    for (var i = 0; i < pairs.length; i++) {
      var parts = pairs[i].split('=');
      var key = decodeUriComponent(parts[0]);
      var value = parts.length > 1 ? decodeUriComponent(parts[1]) : '';
      if (params.hasOwnProperty(key)) {
        if (!isArray(params[key])) {
          params[key] = [params[key]];
        }
        params[key].push(value);
      } else {
        params[key] = value;
      }
    }
  }
  return params;
}

function buildQueryString(params) {
  var pairs = [];
  for (var key in params) {
    if (params.hasOwnProperty(key)) {
      var values = isArray(params[key]) ? params[key] : [params[key]];
      for (var i = 0; i < values.length; i++) {
        if (values[i] === '') {
          if (!bareParamRemoval) {
            pairs.push(encodeUriComponent(key));
          }
        } else {
          pairs.push(encodeUriComponent(key) + '=' + encodeUriComponent(values[i]));
        }
      }
    }
  }
  return pairs.join('&');
}

function applyModification(value, action) {
  if (action === 'remove') {
    return null;
  } else if (action === 'downcase') {
    return value.toLowerCase();
  } else if (action === 'upcase') {
    return value.toUpperCase();
  }
  return value;
}

debugLog('Input URL: ' + url);
debugLog('Modification Table: ' + stringifyObject(modificationTable));
debugLog('Remove Except One: ' + removeExceptOne);
debugLog('Keep Which: ' + keepWhich);
debugLog('Bare Parameter Removal: ' + bareParamRemoval);

if (!url) {
  logError('Input URL is empty or undefined');
  return url;
}

var queryParams = getQueryParams(url);
debugLog('Original Query Params: ' + stringifyObject(queryParams));

var modifiedParams = {};
for (var key in queryParams) {
  if (queryParams.hasOwnProperty(key)) {
    var values = isArray(queryParams[key]) ? queryParams[key] : [queryParams[key]];
    var modifiedValues = [];
    
    for (var i = 0; i < values.length; i++) {
      var value = values[i];
      var isRemoved = false;
      
      if (modificationTable && modificationTable.length) {
        for (var j = 0; j < modificationTable.length; j++) {
          if (modificationTable[j] && modificationTable[j].query_name === key) {
            var action = modificationTable[j].modification;
            debugLog('Applying modification for ' + key + ': ' + action);
            
            value = applyModification(value, action);
            
            if (value === null) {
              isRemoved = true;
              break;
            }
          }
        }
      }
      
      if (!isRemoved) {
        modifiedValues.push(value);
        debugLog('Final value for ' + key + '[' + i + ']: ' + value);
      } else {
        debugLog('Removed value for ' + key + '[' + i + ']');
      }
    }
    
    if (modifiedValues.length > 0) {
      if (removeExceptOne && modifiedValues.length > 1) {
        modifiedValues = keepWhich === 'first' ? [modifiedValues[0]] : [modifiedValues[modifiedValues.length - 1]];
        debugLog('Kept ' + keepWhich + ' occurrence for ' + key + ': ' + modifiedValues[0]);
      }
      modifiedParams[key] = modifiedValues.length === 1 ? modifiedValues[0] : modifiedValues;
    } else {
      debugLog('Removed all values for parameter: ' + key);
    }
  }
}

debugLog('Modified Params: ' + stringifyObject(modifiedParams));

var modifiedQueryString = buildQueryString(modifiedParams);
var baseUrl = url.split('?')[0];
var result = baseUrl + (modifiedQueryString ? '?' + modifiedQueryString : '');

debugLog('Result URL: ' + result);

if (hasError) {
  log('Errors occurred while processing URL. Returning original URL.');
  return url;
}

return result;


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Basic Modification
  code: |-
    const mockData1 = {
      url: "https://example.com?utm_source=google&utm_medium=cpc",
      modification_table: [{query_name: "utm_source", modification: "upcase"}],
      debug_mode: false,
      remove_except_first: false,
      keep_which: "first",
      bare_param_removal: false
    };

    let variableResult1 = runCode(mockData1);
    assertThat(variableResult1).isEqualTo("https://example.com?utm_source=GOOGLE&utm_medium=cpc");
- name: Remove Parameter
  code: |-
    const mockData = {
      url: "https://example.com?param1=value1&param2=value2&param3=value3",
      modification_table: [{query_name: "param2", modification: "remove"}],
      debug_mode: false,
      remove_except_first: false,
      keep_which: "first",
      bare_param_removal: false
    };

    let variableResult = runCode(mockData);
    assertThat(variableResult).isEqualTo("https://example.com?param1=value1&param3=value3");
- name: Keep First Occurrence
  code: |-
    const mockData = {
      url: "https://example.com?param=value1&param=value2&param=value3",
      modification_table: [],
      debug_mode: false,
      remove_except_first: true,
      keep_which: "first",
      bare_param_removal: false
    };

    let variableResult = runCode(mockData);
    assertThat(variableResult).isEqualTo("https://example.com?param=value1");
- name: Remove Bare Parameters
  code: |-
    const mockData = {
      url: "https://example.com?param1=value1&param2&param3=&param4",
      modification_table: [],
      debug_mode: false,
      remove_except_first: false,
      keep_which: "first",
      bare_param_removal: true
    };

    let variableResult = runCode(mockData);
    assertThat(variableResult).isEqualTo("https://example.com?param1=value1&param3=");
- name: Complex Case - Multiple Modifications
  code: |-
    const mockData = {
      url: "https://example.com?utm_source=google&UTM_MEDIUM=cpc&campaign=summer&campaign=winter&ref&empty=",
      modification_table: [
        {query_name: "utm_source", modification: "upcase"},
        {query_name: "UTM_MEDIUM", modification: "downcase"},
        {query_name: "campaign", modification: "remove"}
      ],
      debug_mode: false,
      remove_except_first: true,
      keep_which: "last",
      bare_param_removal: true
    };

    let variableResult = runCode(mockData);
    assertThat(variableResult).isEqualTo("https://example.com?utm_source=GOOGLE&utm_medium=cpc&empty=");


___NOTES___

Created on 7/19/2024, 9:47:11 AM


