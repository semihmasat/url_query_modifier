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
  "categories": ["UTILITY"],
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
    "displayName": "",
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
            "value": "Upcase",
            "displayValue": "Upcase"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const decodeUriComponent = require('decodeUriComponent');
const encodeUriComponent = require('encodeUriComponent');

var url = data.url;
var modificationTable = data.modification_table;

// Function to parse the query parameters into an object
function getQueryParams(url) {
  var params = {};
  var queryString = url.split('?')[1];
  if (queryString) {
    var pairs = queryString.split('&');
    for (var i = 0; i < pairs.length; i++) {
      var parts = pairs[i].split('=');
      params[decodeUriComponent(parts[0])] = decodeUriComponent(parts[1] || '');
    }
  }
  return params;
}

// Function to build the query string from an object
function buildQueryString(params) {
  var queryString = '';
  for (var key in params) {
    if (params.hasOwnProperty(key)) {
      if (queryString !== '') {
        queryString += '&';
      }
      queryString += encodeUriComponent(key) + '=' + encodeUriComponent(params[key]);
    }
  }
  return queryString;
}

// Get the query parameters from the URL
var queryParams = getQueryParams(url);

// Apply the modifications from the modification table
var modifiedParams = {};
for (var key in queryParams) {
  if (queryParams.hasOwnProperty(key)) {
    var action = null;
    for (var i = 0; i < modificationTable.length; i++) {
      if (modificationTable[i].query === key) {
        action = modificationTable[i].modification;
        break;
      }
    }

    if (action === 'remove') {
      // Skip adding this key to modifiedParams to effectively remove it
      continue;
    } else if (action === 'downcase') {
      modifiedParams[key] = queryParams[key].toLowerCase();
    } else if (action === 'upcase') {
      modifiedParams[key] = queryParams[key].toUpperCase();
    } else {
      // If no action or unrecognized action, copy the original value
      modifiedParams[key] = queryParams[key];
    }
  }
}

// Build the modified query string
var modifiedQueryString = buildQueryString(modifiedParams);

// Return the modified URL
var baseUrl = url.split('?')[0];
return baseUrl + '?' + modifiedQueryString;


___TESTS___

scenarios: []


___NOTES___

Created on 7/19/2024, 9:47:11 AM


