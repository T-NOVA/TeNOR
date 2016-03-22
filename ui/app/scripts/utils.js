'use strict';

function dynamicSort(property) {
    var sortOrder = 1;
    if (property[0] === "-") {
        sortOrder = -1;
        property = property.substr(1);
    }
    return function (a, b) {
        var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
        return result * sortOrder;
    };
}

function containsObject(obj, list, key) {
    for (var i = 0; i < list.length; i++) {
        if (list[i][key] == obj[key]) {
            return true;
        }
    }
    return false;
}

function checkIfIsArray(possibleArray) {
    if (possibleArray instanceof Array) {
        return possibleArray;
    } else {
        return [possibleArray];
    }
}
