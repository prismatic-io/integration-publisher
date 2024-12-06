# Prismatic Integration Publisher

This GitHub Action publishes an integration via Prismatic's Prism CLI.

## Inputs

- **PRISMATIC_URL** (required): The target Prismatic API to publish to.
- **PRISM_REFRESH_TOKEN** (required): The token granting access to the API at the PRISMATIC_URL provided.
- **PATH_TO_CNI** (optional): The path to the Code Native Integration source code, usually the same location as the CNI's package.json. If not provided, the root will be used.
- **PATH_TO_YML** (optional): The path to the integration yml file that is to be published.
- **INTEGRATION_ID** (required): The ID of the integration to be published. Corresponds to the Prismatic environment defined by the PRISMATIC_URL.
- **SKIP_COMMIT_HASH_PUBLISH** (optional): Skip inclusion of commit hash in metadata. Default is `false`.
- **SKIP_COMMIT_URL_PUBLISH** (optional): Skip inclusion of commit URL in metadata. Default is `false`.
- **SKIP_REPO_URL_PUBLISH** (optional): Skip inclusion of repository URL in metadata. Default is `false`.
- **SKIP_PULL_REQUEST_URL_PUBLISH** (optional): Skip inclusion of pull request URL in metadata. Default is `false`.
- **OVERVIEW** (optional): Overview to describe the purpose of the integration (used in conjunction with <u>MAKE_AVAILABLE_IN_MARKETPLACE</u>).
- **MAKE_AVAILABLE_IN_MARKETPLACE** (optional): Make version available in the marketplace.

## PATH_TO_CNI vs PATH_TO_YML

Use `PATH_TO_CNI` if publishing a Code Native Integration. Use `PATH_TO_YML` if publishing an integration defined in a YML file only. In the unlikely scenario that both are provided, an error will be thrown.

## Example Usage

To use this action in your workflow, add the following step configuration to your workflow file (this assumes that `PRISMATIC_URL` is stored in a Github environment's `variables` and that `PRISM_REFRESH_TOKEN` is stored in the same environment's `secrets`):

```yaml
- name: <STEP NAME>
  uses: prismatic-io/integration-publisher@<LATEST_VERSION>
  with:
    PATH_TO_YML: <PATH_TO_YML>
    PRISMATIC_URL: ${{ vars.PRISMATIC_URL }}
    PRISM_REFRESH_TOKEN: ${{ secrets.PRISM_REFRESH_TOKEN }}
    INTEGRATION_ID: <INTEGRATION_ID>
```

or

```yaml
- name: <STEP NAME>
  uses: prismatic-io/integration-publisher@<LATEST_VERSION>
  with:
    PATH_TO_CNI: <PATH_TO_CNI>
    PRISMATIC_URL: ${{ vars.PRISMATIC_URL }}
    PRISM_REFRESH_TOKEN: ${{ secrets.PRISM_REFRESH_TOKEN }}
    INTEGRATION_ID: <INTEGRATION_ID>
```

Optional inputs can be passed via the `with` block as desired.

### Additional Workflow Steps - CNI only

The following steps are an example of preparing the CNI bundle prior to publishing via this action. The `working-directory` will likely match the `PATH_TO_CNI` input passed to the integration-publisher action.

```yaml
- uses: actions/checkout@v4

- name: Install dependencies
  run: npm install
  working-directory: src/my-cni

- name: Build integration bundle
  run: npm run build
  working-directory: src/my-cni
```

## Acquiring PRISM_REFRESH_TOKEN

To acquire a refresh token that will authenticate against the Prism CLI, run this command in a terminal (assuming you are authenticated with the CLI):

```
prism me:token --type=refresh
```

This will produce a token valid for the Prismatic stack that your CLI is currently configured to. To check which API Prism is currently configured for, run:

```
prism me
```

## What is Prismatic?

Prismatic is the leading embedded iPaaS, enabling B2B SaaS teams to ship product integrations faster and with less dev time. The only embedded iPaaS that empowers both developers and non-developers with tools for the complete integration lifecycle, Prismatic includes low-code and code-native building options, deployment and management tooling, and self-serve customer tools.

Prismatic's unparalleled versatility lets teams deliver any integration from simple to complex in one powerful platform. SaaS companies worldwide, from startups to Fortune 500s, trust Prismatic to help connect their products to the other products their customers use.

With Prismatic, you can:

- Build [integrations](https://prismatic.io/docs/integrations/) using our [intuitive low-code designer](https://prismatic.io/docs/integrations/low-code-integration-designer/) or [code-native](https://prismatic.io/docs/integrations/code-native/) approach in your preferred IDE
- Leverage pre-built [connectors](https://prismatic.io/docs/components/) for common integration tasks, or develop custom connectors using our TypeScript SDK
- Embed a native [integration marketplace](https://prismatic.io/docs/embed/) in your product for customer self-service
- Configure and deploy customer-specific integration instances with powerful configuration tools
- Support customers efficiently with comprehensive [logging, monitoring, and alerting](https://prismatic.io/docs/monitor-instances/)
- Run integrations in a secure, scalable infrastructure designed for B2B SaaS
- Customize the platform to fit your product, industry, and development workflows

## Who uses Prismatic?

Prismatic is built for B2B software companies that need to provide integrations to their customers. Whether you're a growing SaaS startup or an established enterprise, Prismatic's platform scales with your integration needs.

Our platform is particularly powerful for teams serving specialized vertical markets. We provide the flexibility and tools to build exactly the integrations your customers need, regardless of the systems you're connecting to or how unique your integration requirements may be.

## What kind of integrations can you build using Prismatic?

Prismatic supports integrations of any complexity - from simple data syncs to sophisticated, industry-specific solutions. Teams use it to build integrations between any type of system, whether modern SaaS or legacy with standard or custom protocols. Here are some example use cases:

- Connect your product with customers' ERPs, CRMs, and other business systems
- Process data from multiple sources with customer-specific transformation requirements
- Automate workflows with customizable triggers, actions, and schedules
- Handle complex authentication flows and data mapping scenarios

For information on the Prismatic platform, check out our [website](https://prismatic.io/) and [docs](https://prismatic.io/docs/).

## License

This repository is MIT licensed.
