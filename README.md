# Mortgage Assistant UI

The Mortgage Assistant UI is a specialized Next.js application designed to provide intelligent mortgage guidance and loan processing assistance. Built on LangGraph infrastructure, it enables seamless conversations with mortgage domain experts through an intuitive chat interface.

## 🏠 Features

- **Mortgage Loan Guidance**: Interactive assistance for home loan applications, refinancing, and mortgage calculations
- **Document Processing**: AI-powered analysis of financial documents and loan paperwork
- **Real-time Calculations**: Dynamic mortgage payment calculations, interest rate comparisons, and affordability assessments
- **Personalized Recommendations**: Tailored loan product suggestions based on individual financial profiles
- **Containerized Deployment**: Production-ready with OpenShift and Kubernetes support
- **Enterprise Security**: SCC-compliant container architecture with non-root user permissions

## 🚀 Quick Start

Clone the repository:

```bash
git clone https://github.com/your-org/mortgage-assistant-ui.git
cd mortgage-assistant-ui
```

Install dependencies:

```bash
pnpm install
```

Run the development server:

```bash
pnpm dev
```

The Mortgage Assistant will be available at `http://localhost:3000`.

## 📋 Usage

### Development Setup

The Mortgage Assistant connects to a LangGraph server running your mortgage domain logic. You'll need:

- **LangGraph Server**: Your mortgage assistant backend (typically running at `http://localhost:2024`)
- **Assistant ID**: The mortgage assistant graph identifier (e.g., "mortgage-agent")
- **API Configuration**: Authentication settings for production deployments

### Mortgage Assistant Capabilities

Once connected, you can:

- **Apply for Home Loans**: Guide users through mortgage applications with intelligent form assistance
- **Calculate Payments**: Real-time mortgage payment calculations with various loan scenarios
- **Document Analysis**: Upload and analyze financial documents, pay stubs, and tax returns
- **Rate Comparisons**: Compare interest rates across different loan products and lenders
- **Refinancing Analysis**: Evaluate refinancing opportunities and potential savings
- **Pre-approval Assistance**: Help users understand pre-approval requirements and process

## ⚙️ Environment Variables

Configure the Mortgage Assistant by setting these environment variables:

### Development Configuration

```bash
# Mortgage Assistant API Configuration
NEXT_PUBLIC_API_URL=http://localhost:2024
NEXT_PUBLIC_ASSISTANT_ID=mortgage-agent

# Optional: Skip the setup form with these defaults
NEXT_PUBLIC_DEFAULT_MORTGAGE_LENDER=YourBank
NEXT_PUBLIC_DEFAULT_LOAN_TYPE=conventional
```

### Production Configuration

```bash
# Production LangGraph Server
LANGGRAPH_API_URL=https://your-mortgage-api.company.com
NEXT_PUBLIC_API_URL=https://your-mortgage-ui.company.com/api
NEXT_PUBLIC_ASSISTANT_ID=mortgage-agent

# Authentication (keep secret!)
LANGSMITH_API_KEY=lsv2_your_api_key_here
```

### Container Environment

```bash
# Container-specific settings
NODE_ENV=production
PORT=8080
HOSTNAME=0.0.0.0
LANGGRAPH_API_URL=http://host.containers.internal:2024
```

To configure:

1. Copy `.env.example` to `.env`
2. Update values for your mortgage backend
3. Restart the application

> [!TIP]
> For production deployment, see the [Container Deployment](#container-deployment) section.

## 🐳 Container Deployment

The Mortgage Assistant is fully containerized and ready for enterprise deployment on OpenShift and Kubernetes.

### Quick Container Start

```bash
# Pull from public registry
podman pull quay.io/rbrhssa/mortgage-agent-ui:latest

# Run with local LangGraph server
podman run -p 8080:8080 \
  -e LANGGRAPH_API_URL=http://host.containers.internal:2024 \
  quay.io/rbrhssa/mortgage-agent-ui:latest
```

### OpenShift Deployment

```bash
# Deploy to OpenShift
oc apply -f k8s/

# Or use Kustomize
oc apply -k k8s/

# Check deployment status
oc get pods -l app=mortgage-assistant-ui
```

### Build Your Own Image

```bash
# Build container image
make build

# Push to registry
make push

# Full OpenShift deployment
make oc-full-deploy
```

For complete deployment instructions, see:
- [Container Deployment Guide](CONTAINER_DEPLOYMENT.md)
- [Quay.io Registry Guide](QUAY_DEPLOYMENT.md)

## 🎛️ Customizing Chat Behavior

You can control the visibility and behavior of messages within the Mortgage Assistant UI:

**1. Prevent Live Streaming:**

For sensitive mortgage calculations or document processing, you may want to prevent streaming and show complete results only:

_Python Example (Mortgage Domain):_

```python
from langchain_anthropic import ChatAnthropic

# Prevent streaming for sensitive mortgage calculations
mortgage_calculator = ChatAnthropic().with_config(
    config={"tags": ["langsmith:nostream"]}
)

# Use for credit score analysis, loan approvals, etc.
credit_analyzer = ChatAnthropic().with_config(
    config={"tags": ["langsmith:nostream"]}
)
```

_TypeScript Example (Mortgage Domain):_

```typescript
import { ChatAnthropic } from "@langchain/anthropic";

// Configure for mortgage-specific operations
const mortgageCalculator = new ChatAnthropic()
  .withConfig({ tags: ["langsmith:nostream"] });

const documentProcessor = new ChatAnthropic()
  .withConfig({ tags: ["langsmith:nostream"] });
```

**Note:** Even if streaming is hidden this way, the message will still appear after the LLM call completes if it's saved to the graph's state without further modification.

**2. Hide Sensitive Processing:**

For mortgage applications, you may need to hide sensitive operations like credit checks or income verification from the UI:

_Python Example (Mortgage Security):_

```python
# Hide sensitive credit score processing
credit_result = credit_model.invoke([messages])
credit_result.id = f"do-not-render-{credit_result.id}"

# Hide internal loan underwriting decisions
underwriting_result = underwriting_model.invoke([messages])
underwriting_result.id = f"do-not-render-{underwriting_result.id}"

return {"messages": [credit_result, underwriting_result]}
```

_TypeScript Example (Mortgage Security):_

```typescript
// Hide sensitive financial calculations
const creditCheck = await creditModel.invoke([messages]);
creditCheck.id = `do-not-render-${creditCheck.id}`;

// Hide internal risk assessment
const riskAssessment = await riskModel.invoke([messages]);
riskAssessment.id = `do-not-render-${riskAssessment.id}`;

return { messages: [creditCheck, riskAssessment] };
```

This approach guarantees the message remains completely hidden from the user interface.

## 📊 Rendering Mortgage Artifacts

The Mortgage Assistant UI supports rendering financial artifacts like loan summaries, payment schedules, and document analysis results in a dedicated side panel. Common mortgage artifacts include:

- **Loan Estimates**: Official loan estimate forms with terms and costs
- **Payment Schedules**: Amortization tables and payment breakdowns  
- **Document Analysis**: Parsed financial documents and verification results
- **Rate Comparisons**: Side-by-side loan option comparisons
- **Affordability Reports**: Income vs. payment analysis charts

Here's the utility hook for mortgage artifact rendering:

```tsx
export function useArtifact<TContext = Record<string, unknown>>() {
  type Component = (props: {
    children: React.ReactNode;
    title?: React.ReactNode;
  }) => React.ReactNode;

  type Context = TContext | undefined;

  type Bag = {
    open: boolean;
    setOpen: (value: boolean | ((prev: boolean) => boolean)) => void;

    context: Context;
    setContext: (value: Context | ((prev: Context) => Context)) => void;
  };

  const thread = useStreamContext<
    { messages: Message[]; ui: UIMessage[] },
    { MetaType: { artifact: [Component, Bag] } }
  >();

  return thread.meta?.artifact;
}
```

Example mortgage artifact components:

```tsx
import { useArtifact } from "../utils/use-artifact";
import { Calculator, FileText, TrendingUp } from "lucide-react";

export function LoanEstimate(props: {
  loanAmount: number;
  interestRate: number;
  monthlyPayment: number;
  loanTerm: number;
}) {
  const [Artifact, { open, setOpen }] = useArtifact();

  return (
    <>
      <div
        onClick={() => setOpen(!open)}
        className="cursor-pointer rounded-lg border p-4 bg-blue-50 hover:bg-blue-100"
      >
        <div className="flex items-center gap-2">
          <Calculator className="h-5 w-5 text-blue-600" />
          <p className="font-medium">Loan Estimate Generated</p>
        </div>
        <p className="text-sm text-gray-600">
          ${props.loanAmount.toLocaleString()} loan at {props.interestRate}% 
        </p>
        <p className="text-lg font-bold text-blue-600">
          ${props.monthlyPayment}/month
        </p>
      </div>

      <Artifact title="Official Loan Estimate">
        <div className="p-6 space-y-4">
          <h3 className="text-xl font-bold">Loan Estimate</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-sm font-medium">Loan Amount</label>
              <p className="text-lg">${props.loanAmount.toLocaleString()}</p>
            </div>
            <div>
              <label className="text-sm font-medium">Interest Rate</label>
              <p className="text-lg">{props.interestRate}%</p>
            </div>
            <div>
              <label className="text-sm font-medium">Monthly Payment</label>
              <p className="text-lg font-bold">${props.monthlyPayment}</p>
            </div>
            <div>
              <label className="text-sm font-medium">Loan Term</label>
              <p className="text-lg">{props.loanTerm} years</p>
            </div>
          </div>
        </div>
      </Artifact>
    </>
  );
}

export function DocumentAnalysis(props: {
  documentType: string;
  status: "verified" | "pending" | "rejected";
  details?: string;
}) {
  const [Artifact, { open, setOpen }] = useArtifact();

  return (
    <>
      <div
        onClick={() => setOpen(!open)}
        className="cursor-pointer rounded-lg border p-4"
      >
        <div className="flex items-center gap-2">
          <FileText className="h-5 w-5" />
          <p className="font-medium">{props.documentType} Analysis</p>
        </div>
        <div className="flex items-center gap-2 mt-2">
          <span className={`px-2 py-1 rounded-full text-xs ${
            props.status === 'verified' ? 'bg-green-100 text-green-800' :
            props.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
            'bg-red-100 text-red-800'
          }`}>
            {props.status.toUpperCase()}
          </span>
        </div>
      </div>

      <Artifact title={`${props.documentType} Analysis`}>
        <div className="p-4">
          <div className="space-y-2">
            <p><strong>Document:</strong> {props.documentType}</p>
            <p><strong>Status:</strong> {props.status}</p>
            {props.details && (
              <div>
                <strong>Analysis:</strong>
                <p className="whitespace-pre-wrap mt-2">{props.details}</p>
              </div>
            )}
          </div>
        </div>
      </Artifact>
    </>
  );
}
```

## 🏢 Production Deployment

The Mortgage Assistant UI is designed for enterprise deployment with secure authentication and scalable architecture. Production deployments require proper authentication to protect sensitive financial data and comply with regulatory requirements.

### Enterprise Security Considerations

For mortgage applications, additional security measures are essential:

- **Data Encryption**: All financial data transmitted over HTTPS/TLS
- **Audit Logging**: Complete audit trails for compliance (CFPB, GDPR)
- **Session Management**: Secure user session handling with timeout policies
- **Access Controls**: Role-based permissions for loan officers, underwriters, etc.
- **Document Security**: Encrypted storage for financial documents and SSN data

### Production Authentication Options

Choose the appropriate authentication method based on your security requirements:

### Option 1: API Passthrough (Recommended for Mortgage Use)

The API Passthrough method is ideal for mortgage applications as it centralizes authentication and enables audit logging of all financial interactions.

**Mortgage-Specific Configuration:**

```bash
# Mortgage Assistant Configuration
NEXT_PUBLIC_ASSISTANT_ID="mortgage-agent"

# Production Mortgage LangGraph Server
LANGGRAPH_API_URL="https://mortgage-api.yourbank.com"

# Mortgage UI API Endpoint
NEXT_PUBLIC_API_URL="https://mortgage.yourbank.com/api"

# LangSmith API Key (for mortgage conversation tracking)
LANGSMITH_API_KEY="lsv2_mortgage_production_key"

# Optional: Mortgage-specific settings
MORTGAGE_LENDER_ID="YourBank_001"
COMPLIANCE_LOGGING_ENABLED="true"
CFPB_AUDIT_MODE="enabled"
```

**Security Benefits for Mortgage Applications:**

- **Centralized Authentication**: Single point for mortgage system access control
- **Audit Compliance**: All mortgage conversations logged for regulatory compliance
- **Sensitive Data Protection**: API keys and credentials never exposed to client
- **Rate Limiting**: Prevent abuse of mortgage calculation and application APIs
- **Session Management**: Secure handling of customer financial sessions

**Environment Variable Details:**

- `NEXT_PUBLIC_ASSISTANT_ID`: Set to `"mortgage-agent"` for the mortgage domain assistant
- `LANGGRAPH_API_URL`: Your production mortgage LangGraph deployment 
- `NEXT_PUBLIC_API_URL`: Your mortgage UI domain + `/api` (e.g., `https://apply.yourbank.com/api`)
- `LANGSMITH_API_KEY`: Production API key with mortgage conversation tracking enabled
- `MORTGAGE_LENDER_ID`: Optional identifier for multi-lender deployments
- `COMPLIANCE_LOGGING_ENABLED`: Enable enhanced logging for regulatory compliance

For in depth documentation, consult the [LangGraph Next.js API Passthrough](https://www.npmjs.com/package/langgraph-nextjs-api-passthrough) docs.

### Option 2: Custom Mortgage Authentication

For enterprise mortgage deployments requiring advanced access controls, custom authentication provides role-based access for different mortgage stakeholders.

**Mortgage Role-Based Access:**

- **Customers**: Basic loan application and status checking
- **Loan Officers**: Full customer interaction and application management  
- **Underwriters**: Document analysis and approval workflows
- **Compliance Officers**: Audit access and regulatory reporting

**Implementation for Mortgage Systems:**

1. **Configure Mortgage Authentication API**: Set up role-based authentication in your mortgage LangGraph deployment
2. **Set Production URLs**: Configure for your mortgage domain
3. **Implement Role Headers**: Pass mortgage-specific role information

```tsx
// Mortgage-specific authentication implementation
const mortgageStreamValue = useTypedStream({
  apiUrl: process.env.NEXT_PUBLIC_API_URL,
  assistantId: "mortgage-agent",
  defaultHeaders: {
    Authorization: `Bearer ${mortgageAuthToken}`,
    'X-Mortgage-Role': userRole, // customer | loan_officer | underwriter | compliance
    'X-Lender-ID': lenderId,
    'X-Application-ID': applicationId, // For ongoing applications
    'X-Audit-Session': auditSessionId, // For compliance tracking
  },
});
```

**Advanced Mortgage Security Features:**

```tsx
// Enhanced security for mortgage applications
const mortgageConfig = {
  // Encrypt sensitive mortgage data in transit
  encryption: 'AES-256-GCM',
  
  // Audit all mortgage conversations
  auditLogging: true,
  
  // Compliance-specific headers
  complianceHeaders: {
    'X-CFPB-Compliance': 'enabled',
    'X-Privacy-Mode': 'mortgage-pii',
    'X-Data-Classification': 'financial-sensitive'
  },
  
  // Session timeout for sensitive operations
  sessionTimeout: 900, // 15 minutes for mortgage apps
  
  // Rate limiting for mortgage APIs
  rateLimiting: {
    calculationsPerMinute: 30,
    applicationsPerHour: 5,
    documentUploadsPerDay: 20
  }
};
```

## 📁 File Structure

```
mortgage-assistant-ui/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── health/           # Health check endpoint
│   │   │   └── [..._path]/       # LangGraph API proxy
│   │   ├── globals.css           # Global styles with mortgage theme
│   │   ├── layout.tsx            # Root layout
│   │   └── page.tsx              # Main mortgage chat interface
│   ├── components/
│   │   ├── thread/               # Chat interface components
│   │   │   ├── messages/         # Message rendering (Human/AI)
│   │   │   └── agent-inbox/      # LangGraph agent integration
│   │   └── ui/                   # Reusable UI components
│   ├── hooks/                    # Custom React hooks
│   ├── lib/                      # Utility functions
│   └── providers/                # React context providers
├── k8s/                          # OpenShift/Kubernetes manifests
│   ├── deployment.yaml           # Application deployment
│   ├── service.yaml             # Kubernetes service
│   ├── configmap.yaml           # Configuration management
│   ├── route.yaml               # OpenShift external access
│   └── kustomization.yaml       # Kustomize orchestration
├── public/                       # Static assets
├── Containerfile                # Container build definition
├── Makefile                     # Build and deployment automation
├── CONTAINER_DEPLOYMENT.md      # Container deployment guide
├── QUAY_DEPLOYMENT.md          # Registry deployment guide
└── package.json                 # Dependencies and scripts
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/mortgage-enhancement`
3. Make your changes
4. Test with mortgage use cases
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For mortgage-specific questions and enterprise deployment support:

- **Documentation**: [Container Deployment Guide](CONTAINER_DEPLOYMENT.md)
- **Health Check**: `http://localhost:8080/api/health`
- **Container Logs**: `podman logs <container-name>`
- **OpenShift Support**: `oc get pods -l app=mortgage-assistant-ui`
