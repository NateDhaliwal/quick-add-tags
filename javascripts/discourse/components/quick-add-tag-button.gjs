import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

import { fn } from "@ember/helper"
import { action } from "@ember/object";
import { service } from "@ember/service";

import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";

import { eq, or } from "truth-helpers";

export default class QuickAddTagButton extends Component {
  @service currentUser;
  @service toasts;

  @tracked allowedDict = [];

  // get shouldShow() {
  //   const topic = this.args.topic;
  //   const cat_id = topic.category_id;
  //   const settingObj = settings.quick_add_tags_buttons;
  //   console.log(topic);
  //   const canEdit = topic.canEditTags !== undefined;
  //   console.log(canEdit);

  //   for (const settingButton of settingObj) {
  //     if (settingButton.in_categories !== null && settingButton.in_categories.includes(cat_id)) {
  //       if (settingButton.auto_close_topic) {
  //         if (this.currentUser.moderator || this.currentUser.admin || this.currentUser.trust_level == 4) {
  //           console.log("Is mod");
  //           this.allowedDict.push({cat_id: true});
  //         } else {
  //           console.log("Not mod");
  //           this.allowedDict.push({cat_id: false});
  //         }
  //       } else {
  //         console.log("Not auto close");
  //         this.allowedDict.push({cat_id: canEdit});
  //       }
  //     }
  //   }
  //   console.log(this.allowedDict);
  //   return true; // this.allowedDict.find(id_bool => id_bool == cat_id);
  // }

  @action
  async addTag(setting_button) {
    const topic = this.args.topic;
    const currentTags = topic.tags;
    const settingTags = setting_button.tags_to_add;

    let newTags = currentTags;

    settingTags.forEach((tag) => {
      if (!currentTags.includes(tag)) {
        newTags.push(tag);
      }
    });
    
    try {
      if (setting_button.auto_close_topic) {
        await ajax(`/t/${topic.id}/timer.json`, {
          type: "POST",
          data: {
            status_type: "close",
            time: setting_button.auto_close_topic_days * 24 // In hours, multiply by 24 to get days
          }
        });
      }
      await ajax(`/t/-/${topic.id}.json`, {
        type: "PUT",
        data: {
          tags: newTags,
          keep_existing_draft: true
        }
      }).then((response) => {
        this.toasts.success({
          duration: "short",
          data: {
            // eslint-disable-next-line no-undef
            message: I18n.t(themePrefix("added_tag_success_message")),
          },
        });
      });
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e);
      if (e.jqXHR.responseJSON.errors !== undefined) {
        const errors = e.jqXHR.responseJSON.errors;
        errors.forEach((error) => {
          this.toasts.error({
            duration: "short",
            data: {
              message: error
            },
          });
        });
      }
    }
  }

  <template>
    {{#each settings.quick_add_tags_buttons as |setting_button|}}
      {{#if setting_button.auto_close_topic}}
        <p>Auto close</p>
        {{#if (or this.currentUser.moderator this.currentUser.admin (eq this.currentUser.trust_level 4))}}
          <p>Can close</p>
          <DButton
            @action={{fn (this.addTag setting_button)}}
            @icon="tag"
            @label={{themePrefix "quick_add_tag_button_text"}}
            @title={{themePrefix "quick_add_tag_button_title"}}
            class="btn-text"
          />
        {{/if}}
      {{else if (this.args.topic.canEditTags)}}
        <p>Can edit tags</p>
        <DButton
          @action={{fn (this.addTag setting_button)}}
          @icon="tag"
          @label={{themePrefix "quick_add_tag_button_text"}}
          @title={{themePrefix "quick_add_tag_button_title"}}
          class="btn-text"
        />
      {{/if}}
    {{/each}}
  </template>
}
