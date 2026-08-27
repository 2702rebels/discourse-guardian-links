import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsGuardianLinksRoute extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/guardian-links/links.json").then((result) => {
      return result.guardian_links || [];
    });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set("links", model);
    controller.set("parentUsername", "");
    controller.set("studentUsername", "");
    controller.set("relationshipType", "parent");
    controller.set("isSaving", false);
  }
}
