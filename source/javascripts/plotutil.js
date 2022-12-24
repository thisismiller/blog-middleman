const zip = (a, b) => a.map((k, i) => [k, b[i]]);

function tableToData(tableId) {
    var tblhdr = $(`table#${tableId} tr`).get().map(function(row) {
    return $(row).find('th').get().map(function(cell) {
        return $(cell).text();
    }).slice(0,3);
    })[0];

    var tbldata = $(`table#${tableId} tr`).get().map(function(row) {
    return Object.fromEntries(zip(tblhdr, $(row).find('td').get().map(function(cell) {
        return $(cell).text();
    }).slice(0,3)));
    }).slice(1);

    return tbldata;
}
