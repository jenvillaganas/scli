# Do not use:
** Use solana-tokens distribute-spl-tokens instead

# SPL Token Transfer Script

## Usage
Install Dependencies
```
  bundle install
```

Run ws Server
```
  ruby server.rb
```

On your client side you can connect to `ws://localhost:8082`
and send transfer message
```rb
  # This example is in ruby
  json = {event: "spl-transfer", token_address: token_address, recipients: recipients}.to_json
  ws.send(json)
```

The server will send a response back to the client once the transfer is completed
```
# Sample Response
{
  status: 200, 
  signature: {
    success_count: 100, 
    failed_count: 2, 
    success: [
      {
        address: "wallet-address",
        signature: "transaction signature",
        error: "if there's any error"
      }
    ], 
    failed: [
      {
        address: "wallet-address",
        error: "if there's any error"
      }
    ],
    completed: "addresses_in_arrays"
  }
}
```
