import Component from "@glimmer/component";

import { action } from "@ember/object";
import { service } from "@ember/service";

import DButton from "discourse/components/d-button";

export default class QuickAddTagButton extends Component {
  @service toasts;

  get shouldShow() {
    return this.args.topic.details.can_edit;
  }

  @action
  async addTag() {
    const topic = this.args.topic;
    const currentTags = this.args.topic.tags;
    const settingTags = settings.quick_add_tags;
    const newTags = currentTags;
    settingTags.forEach((tag) => {
      newTags.push(tag);
    });

    await topic.save({
      tags: newTags
    }).then(() => {
      this.toasts.success({
        duration: "short",
        data: {
          message: I18n.t(themePrefix("added_tag_success_message")),
        },
      });
    });
  }

  <template>
    {{#if this.shouldShow}}
      <DButton
        @action={{this.addTag}}
        @icon="tag"
        @label={{themePrefix "quick_add_tag_button_text"}}
        @title={{themePrefix "quick_add_tag_button_title"}}
        class="btn-text"
      />
    {{/if}}
  </template>
}
