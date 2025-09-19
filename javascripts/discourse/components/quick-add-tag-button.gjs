import Component from "@glimmer/component";

import { action } from "@ember/object";
import { service } from "@ember/service";

import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";

export default class QuickAddTagButton extends Component {
  @service toasts;

  get shouldShow() {
    return this.args.topic.details.can_edit;
  }

  @action
  async addTag() {
    const topic = this.args.topic;
    const currentTags = topic.tags;
    const settingTags = settings.quick_add_tags.split("|");
    let newTags = currentTags;

    settingTags.forEach((tag) => {
      if (!currentTags.includes(tag)) {
        newTags.push(tag);
      }
    });

    try {
      await ajax(`/t/-/${topic.id}.json`, {
        type: "PUT",
        data: {
          tags: [...newTags],
          keep_existing_draft: true
        }
      }).then((response) => {
        if (response.ok) {
          this.toasts.success({
            duration: "short",
            data: {
              message: I18n.t(themePrefix("added_tag_success_message")),
            },
          });
        }
      });
    } catch (e) {
      const errors = e.jqXHR.responseJSON.errors;
      errors.forEach((error) => {
        this.toasts.error({
          duration: "short",
          data: {
            message: error
          },
        });
      }
    }
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
