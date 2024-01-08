# Purple Pay Specification

## Summary

A standardised implementation for encoding payment requests as URL strings (native tokens, ERC20 tokens) & QR codes enables interoperability and seamless user experience acros the ecosystem.

EIP 67 and ERC 681 are used as references.

There are primarily two types of requests:
1. Direct Transfer Request
2. Interactive Transaction Request

Both of these request types should be able to support payments in native tokens (Ether, Matic) and ERC20 (USDC, USDT).

## Constraints of EVM Ecosystem

1. EVM do not support a mechanism of injecting a unique identifier (like paymentId) into a transaction which can subsequently be indexed and used to search the transaction (unlike Solana where dummy account address injected into the list of accounts involved in a transaction is able to achieve this).
2. Within EVM, the balances of accounts for an ERC20 token is maintained inside the ERC20 contract as a mapping.

Thus, counterfactual addresses need to be used to track each individual payment session from the user.
This requires creation of a factory contract to generate counterfactual address for each payment request. Once the balance of the counterfactual address is confirmed to be greater than or equal to the payment amount requuested, the contract is deployed and payment disbursement is made to the merchant.
This requires the following setup on the part of the merchant integrating the payments protocol:
1. Deploy a factory contract with predict and deploy functionalities
2. Generate a new counterfactual contract address for each payment request and token
3. Track the balance of the counterfactual contract instances to check payment status

Warning: It is important for the applications to independently confirm the status and validity of the transaction before exchanging goods and services.

Ideally, mobile wallets should integrate the parsing functions of URL schema to ensure compatibility and seamless experience for the user.

## Specification Direct Transfer Request

Direct Transfer Request is a URL encoding scheme which can be used by a wallet to directly create and inititate a transaction

For ERC20 transfers

```
ethereum:<tokenAddress>@<chainId>/transfer
    ?uint256=<amount>
    &address=<recipient>
    &label=<label>
    &message=<message>
    &redirectURL=<redirectURL>
```

For Native transfers

```
ethereum:<recipient>@<chainId>
    ?value=<amount>
    &label=<label>
    &message=<message>
    &redirectURL=<redirectURL>
```

### Recipient

It is the address that is receiving the payment.
To receive an ERC20 token (USDC), tokenAddress field needs to be populated.

### Amount

Amount field is the amount of token to be transferred. It must be non-negative integer.
Wallet should prompt the user for amount if value is not provided.

### Token Address

tokenAddress field should contain the address of the ERC20 token being used to transfer the payment in.

### Redirect URL

redirectURL field should be a URL-encoded absolute HTTPS or ethereum: URL.

This optional query paramaeter enables wallet to URL-decode the value and display it to the user.

This parameter is needed for exchange of information between the wallet and the merchant server to receive transaction hash, payment confirmation etc.

redirectURL should be followed only if the transaction is successful.

There may be atleast two following cases that can be encoded in this parameter:

- If the redirect is a HTTPS URL then the wallet should open the URL using any browser.
- This may be a browser included in the wallet. If it is a ethereum: URL then the wallet should treat it as a new Purple Pay request.

This needs to be paired with a signature scheme to ensure integrity of the wallet making the request to the server.

### Label

label should be a URL-encoded UTF-8 string to describe the recipient of the transfer request (merchant, brand, store, application, individual).

This parameter is decoded and shown to the user by the wallet for additional context vis-a-vis the recipient/merchant

### Message

message should be a URL-encoded UTF-8 string that describes the details of the transfer request.

This may contain item details, order details, acknowledgement of transaction completion for additional context.
This parameter is decoded and shown to the user by the wallet for additional context vis-a-vis the recipient/merchant

### Chain Id

chainId should be used to specify the chain handling the transaction.


## Specification: Interactive Transaction Request
It creates the structure for enabling interactive request and bi-directional communication between wallets and other etntities within the context of a transaction.

ethereum:<link>
Another option: ethereum:<recipient>?request=<link>
Tracks the initial recipient and the final recipient recieved in the POST response - additional safety

The wallet can make an HTTPS request by using the parameters in the URL and subsequently create a transaction.

### Link
A single link field is required as the pathname. The value must be a conditionally URL-encoded absolute HTTPS URL.

If the URL contains query parameters, it must be URL-encoded. Protocol query parameters may be added to this specification. URL-encoding the value prevents conflicting with protocol parameters.
If the URL does not contain query parameters, it should not be URL-encoded. This produces a shorter URL and a less dense QR code.

In either case, the wallet must URL-decode the value. This has no effect if the value isn't URL-encoded. If the decoded value is not an absolute HTTPS URL, the wallet must reject it as malformed.


#### GET Request
The wallet should make an HTTP GET JSON request to the URL. The request should not identify the wallet or the user.
The wallet should make the request with an Accept-Encoding header, and the application should respond with a Content-Encoding header for HTTP compression.
The wallet should display the domain of the URL as the request is being made.

#### GET Response
The wallet must handle HTTP client error, server error, and redirect responses. The application must respond with these, or with an HTTP OK JSON response with a body of

```
{"label":"<label>","icon":"<icon>"}
```

The <label> value must be a UTF-8 string that describes the source of the transaction request. For example, this might be the name of a brand, store, application, or person making the request.
The <icon> value must be an absolute HTTP or HTTPS URL of an icon image. The file must be an SVG, PNG, or WebP image, or the wallet must reject it as malformed.

The wallet should not cache the response except as instructed by HTTP caching response headers.
The wallet should display the label and render the icon image to user.

#### POST Request
The wallet must make an HTTP POST JSON request to the URL with a body of

```
{"account":"<account>"}
```

The <account> value must be the public key of an account that may sign the transaction.
The wallet should make the request with an Accept-Encoding header, and the application should respond with a Content-Encoding header for HTTP compression.
The wallet should display the domain of the URL as the request is being made. If a GET request was made, the wallet should also display the label and render the icon image from the response.

#### POST Response
The wallet must handle HTTP client error, server error, and redirect responses. The application must respond with these, or with an HTTP OK JSON response with a body of

```
{"transaction":"<transaction>"}
```
The <transaction> value must be a base64-encoded serialized transaction. The wallet must base64-decode the transaction and deserialize it.

The application may respond with a partially or fully signed transaction. The wallet must validate the transaction as untrusted.

The wallet must only sign the transaction with the account in the request, and must do so only if a signature for the account in the request is expected.

If any signature except a signature for the account in the request is expected, the wallet must reject the transaction as malicious.

The application may also include an optional message field in the response body:

```
{"message":"<message>","transaction":"<transaction>"}
```

The <message> value must be a UTF-8 string that describes the nature of the transaction response.

For example, this might be the name of an item being purchased, a discount applied to the purchase, or a thank you note. The wallet should display the value to the user.

The wallet and application should allow additional fields in the request body and response body, which may be added by future specification.



