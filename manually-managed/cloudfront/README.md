# AWS CloudFront & WAF

To protect the production instance of the API from from abuse, we point the DNS records for the API to CloudFront (AWS’s CDN) instead of directly to the API service’s load balancer. We also add some WAF (firewall) rules to the CloudFront distribution.

- CloudFront…
    - Needs a separate SSL certificate in the `us-east-1` (N. Virginia) region. It’s set up the same way certificates are set up for the rest of the Kubernetes cluster in AWS Certificate Manager.
    - Is in the NA/Europe price class.
    - The origin:
        - Uses the domain of the API service in the Kubernetes cluster (not a direct reference to the load balancer).
        - Is HTTPS-only.
        - Uses origin shield.
    - Has a default behavior that:
        - Redirects HTTP to HTTPS
        - Allows all HTTP methods
        - Caches GET, HEAD, OPTIONS
        - Forwards all headers to the origin (the `AllViewer` origin request policy)
        - Has a cache policy that:
            - Includes `Authorization` and `Accept` headers and `_webpage-versions-db_session` cookies, and all query strings in the cache key.
            - Compression support is enabled.
        - Has a response headers policy that allows CORS authorization from the monitoring UI. See [`api-cors-authorization-response-headers-policy.json`](./api-cors-authorization-response-headers-policy.json) for the full policy.

            It’s loosely based on AWS’s built-in “CORS-with-preflight-and-SecurityHeadersPolicy” policy, but allows auth headers. We treat those headers specially on the server side to avoid XSS risks: they are only respected for some routes, and sessions are disabled, so cookies won't work.

- There is a WAF ACL attached to the CloudFront distribution.
    - It uses the `AWS-AWSManagedRulesKnownBadInputsRuleSet` built-in rule set.
    - It uses a `per-ip-rate-limit` rule to block IP addresses requesting over a certain rate.
