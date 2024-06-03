const functions = require('firebase-functions');
const {logger} = require("firebase-functions/v2");
const braintree = require("braintree");
const admin = require('firebase-admin');
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.database();
const authUrl = "https://api-m.paypal.com/v1/oauth2/token";

var emailBatchHeader = {
    recipient_type: 'EMAIL',
    email_subject: 'You have a commission payout!',
    email_message: 'You have recieved a commission payout for daily solution sales by BidNote LLC'
  };
var phoneBatchHeader = {
    recipient_type: 'PHONE',
    note: 'You recieved a commission payout!'
  };
var gateway = new braintree.BraintreeGateway({
    environment: braintree.Environment.Production,
    merchantId: "j2tynpwbtgbhr5v8",
    publicKey: "5xtv6r4cx6q6mdtc",
    privateKey: "bebbd4f8293a4e8a6eab2615150399d5",
  });
exports.createPay = functions.https.onCall(async (data, context) => {
    const { nonce, amountTotal } = data;

    return new Promise(function (resolve, reject) {
        gateway.transaction.sale({
            amount: amountTotal,
            paymentMethodNonce: nonce,
            options: {
              submitForSettlement: true,
            }
          },
          function (err, result) {
            if (err) {
                reject(err)
            } else {
                resolve(result)
            }
        })
    })
    .then(result => {
        if (result.transaction.status === "submitted_for_settlement" || result.transaction.status === "settled" || result.transaction.status === "settling") {
            console.log("AUTHORIZED");
            console.log(result.transaction.status);
            console.log("success");
            return {
                'status': 'SUCCESS',
                newPayment: result.transaction.id
            };
        }
        console.log(result.transaction.status);
        console.log(result.transaction.id);
        return {
            'status': 'FAIL',
            newPayment: result.transaction.id
        };
    })
    .catch(error => {
        console.log(error);
        return error;
    });
});
exports.createCust = functions.https.onCall(async (data, context) => {
    return data;
});
exports.updateFeed = functions.https.onCall(async (data, context) => {
    return data;
});
exports.payoutCall = functions.https.onCall(async (data, context) => {
    const { priceData, idData, idType }  = data;
    var totalPayoutItems = [];
    var payoutType = "";
    console.log(priceData);
    console.log(idData);
    const priceArray = priceData.split("/");
    const idArray = idData.split("/");
    console.log(idArray.length);
    console.log(priceArray.length);
    for (var i = 0; i < idArray.length - 1; i++) {
        var obj = {receiver: idArray[i], amount: {value: priceArray[i], currency: 'USD'}};
        if (idType == "phone") {
            obj = {receiver: idArray[i], amount: {value: priceArray[i], currency: 'USD'}, recipient_wallet: "VENMO", alternate_notification_method: { phone: { country_code: "1", national_number: idArray[i]}}};
        } else if (idType == "venmoEmail") {
            obj = {receiver: idArray[i], amount: {value: priceArray[i], currency: 'USD'}, recipient_wallet: "VENMO", note: "Your daily commission payout from BidNote!"};
        }
        if (idArray[i] !== "" && priceArray[i] !== "") {
            totalPayoutItems.push(obj);
        }
    }
    console.log(totalPayoutItems);
    if (totalPayoutItems.length > 0) {
        fetch(authUrl, { 
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Accept-Language': 'en_US',
                'Authorization': `Basic ${base64}`,
            },
            body: 'grant_type=client_credentials'
        }).then(function(response) {
            return response.json();
        }).then(function(data) {
            console.log(data.access_token);
            if (data.access_token !== "" && idType !== "phone") {
                console.log("email payout");
                fetch(payUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${data.access_token}`
                    },
                    body: JSON.stringify({ "sender_batch_header": emailBatchHeader, "items": totalPayoutItems })
                }).then(function(response) {
                    return response.json();
                }).then(function(data) {
                    console.log("Successful payout batch");
                    console.log(data.batch_header.payout_batch_id);
                }).catch(function() {
                    console.log("could not succeed payout");
                });
            } else if (data.access_token !== "" && idType === "phone") {
                console.log("phone payout");
                fetch(payUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${data.access_token}`
                    },
                    body: JSON.stringify({ "sender_batch_header": phoneBatchHeader, "items": totalPayoutItems })
                }).then(function(response) {
                    return response.json();
                }).then(function(data) {
                    console.log("Successful payout batch");
                    console.log(data.batch_header.payout_batch_id);
                }).catch(function() {
                    console.log("could not succeed payout");
                });
            }
        }).catch(function() {
            console.log("couldn't get auth token");
        });
    }
    return data;
});


exports.oneSignalCall = functions.https.onCall(async (data, context) => {
    const { userKey, notif_message }  = data;
    const options = {
        method: 'POST',
        headers: {
          accept: 'application/json',
          Authorization: 'Basic NjU3NjEyOTQtMjYzNS00OWQ3LWI2YzItZTQwZWUyNjYyYWIz',
          'content-type': 'application/json'
        },
        body: JSON.stringify({
          app_id: 'c2b5ad61-32d4-446b-9715-dba324659bab',
          include_subscription_ids: [userKey],
          contents: {en: notif_message, es: 'Hola!'},
          name: 'Bidnote_Notification_Delivery',
          "ios_badgeType": "Increase",
          "ios_badgeCount": 1
        })
      };
      
      fetch('https://onesignal.com/api/v1/notifications', options)
        .then(response => response.json())
        .then(response => console.log(response))
        .catch(err => console.error(err));
});