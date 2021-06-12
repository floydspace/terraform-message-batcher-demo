import ReactDOM from "react-dom";

import ApolloWrapper from "./ApolloWrapper";
import config from "./config.json";

ReactDOM.render(
  <ApolloWrapper>
    <div>
      <input />
      <button>Send Message</button>
    </div>
  </ApolloWrapper>,
  document.getElementById("root")
);
