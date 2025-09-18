import { apiInitializer } from "discourse/lib/api";
import QuickAddTagButton from "../components/quick-add-tag-button";

export default apiInitializer((api) => {
  api.renderInOutlet("after-topic-footer-main-buttons", QuickAddTagButton);
});
