# Security and Responsible Operation

This agent can coordinate revenue activity, but it should begin with no production access and earn permissions gradually.

## Required safeguards

1. Keep credentials in `agent.env` or the deployment platform's encrypted secret store. Never commit a filled-in environment file.
2. Create dedicated integration accounts with the narrowest permissions the workflow requires.
3. Keep the dashboard private. The default Compose file binds it to localhost.
4. Require human approval for external messages, new partner acceptance, changes to terms or commission, attribution adjustments, payouts, refunds, exports, and destructive actions.
5. Test integrations with synthetic or non-sensitive records before using live partner data.
6. Review logs and pending actions on a recurring schedule. Stop the workflow when unexpected behavior appears.
7. Remove credentials before sharing logs or asking for support.
8. Keep Hermes in manual approval mode, deny approvals from cron, and require
   review for agent-authored skills. The checked defaults are in
   `hermes/config.template.yaml` and `orgo/setup.sh`.
9. For Orgo, keep private contracts, partner lists, paid training, exports, and
   other non-public material under
   `~/.hermes/affiliate-manager/private-business/`.
10. If behavior is unexpected, run
    `./orgo/emergency-stop.sh "reason"`. This records the stop and disables the
    connected business-app MCP without removing research and drafting access.

The detailed action boundary is versioned in `policies/permissions.json`.

## Reporting a security issue

Do not open a public issue containing a credential, personal information, or exploitable detail. Contact the repository owner privately through their public GitHub profile.
