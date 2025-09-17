import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.replaceIcon("shield-halved", "bat-icon");
});
