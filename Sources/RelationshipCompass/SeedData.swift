import Foundation

/// 假数据种子：约 20 条中文联系人，覆盖三种重要度，约 8 人处于待联系
enum SeedData {
    static func make() -> [Contact] {
        func daysAgo(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: Date.now) ?? Date.now
        }

        func i(_ days: Int, _ method: InteractionMethod, _ note: String = "") -> Interaction {
            Interaction(date: daysAgo(days), method: method, notes: note)
        }

        func c(
            _ name: String, _ company: String, _ position: String,
            _ phone: String, _ email: String, _ notes: String,
            _ importance: ImportanceLevel, _ interactions: [Interaction],
            cadenceDays: Int? = nil
        ) -> Contact {
            Contact(
                name: name, company: company, position: position,
                phone: phone, email: email, notes: notes,
                importance: importance, cadenceDays: cadenceDays,
                interactions: interactions
            )
        }

        return [
            // 重要（6）
            c("张伟", "华信科技", "合伙人", "138-1000-0001", "zhangwei@huaxin.cn", "老客户转介绍",
              .important, [i(12, .meeting, "讨论年度合作细节"), i(80, .wechat, "同步项目进度")]),
            c("李娜", "蓝湾资本", "投资总监", "139-1000-0002", "lina@bluebay.com", "天使轮投资人",
              .important, [i(5, .phone, "融资进展沟通"), i(60, .email, "发送商业计划书")]),
            c("王强", "恒瑞医疗", "前部门总监", "137-1000-0003", "wangqiang@hemrai.com", "职业导师",
              .important, [i(45, .wechat, "请教职业规划建议"), i(300, .meeting, "旧同事聚餐")]),
            c("陈静", "云启教育", "采购负责人", "136-1000-0004", "chenjing@yunqi.edu", "重点客户",
              .important, [i(20, .email, "报价已发送"), i(90, .phone, "询价沟通")]),
            c("刘洋", "星辰文创", "CEO", "135-1000-0005", "liuyang@xingchen.com", "核心合作方，每周同步",
              .important, [i(4, .wechat, "本周进度同步"), i(11, .phone, "合同细节确认"), i(25, .meeting, "季度复盘")],
              cadenceDays: 7),
            c("赵敏", "格致研究院", "研究员", "134-1000-0006", "zhaomin@gezhi.ac", "大学挚友",
              .important, [i(60, .meeting, "叙旧吃饭"), i(400, .wechat, "生日祝福")]),

            // 一般（7）
            c("周杰", "锐捷网络", "销售总监", "133-1000-0007", "zhoujie@rjnet.cn", "同行交流",
              .normal, [i(30, .phone, "行业动态交换"), i(150, .email, "活动邀请")]),
            c("吴婷", "简悦咨询", "资深顾问", "132-1000-0008", "wuting@jianyue.cn", "合作过的顾问",
              .normal, [i(120, .wechat, "约见面一直没约上"), i(200, .meeting, "项目复盘")]),
            c("郑浩", "山海证券", "分析师", "131-1000-0009", "zhenghao@shanghai.se", "朋友的朋友",
              .normal, [i(80, .wechat, "转发行业报告")]),
            c("冯蕾", "墨客设计", "主理人", "130-1000-0010", "fenglei@moker.design", "设计师，可推荐客户",
              .normal, [i(200, .meeting, "作品集讨论"), i(400, .wechat, "节日问候")]),
            c("蒋天", "远方物流", "区域经理", "138-1000-0011", "jiangtian@yuanfang.cn", "物流供应商",
              .normal, [i(50, .phone, "报价沟通")]),
            c("韩雪", "灵犀传媒", "策划", "139-1000-0012", "hanxue@lingxi.cn", "同学介绍",
              .normal, [i(95, .wechat, "咨询媒体报价")]),
            c("高峰", "峰峰物流", "车队长", "137-1000-0013", "gaofeng@fengfeng.cn", "家乡朋友",
              .normal, [i(10, .phone, "家常")]),

            // 普通（7）
            c("任远", "顺达贸易", "老板", "136-1000-0014", "renyuan@shunda.cn", "展会认识",
              .ordinary, [i(100, .phone, "闲聊近况")]),
            c("顾青", "星野餐饮", "店长", "135-1000-0015", "guqing@xingye.cn", "常去的餐厅",
              .ordinary, [i(210, .wechat, "预定位子")]),
            c("曹颖", "悦动健身", "教练", "134-1000-0016", "caoying@yuedong.cn", "健身教练",
              .ordinary, [i(150, .meeting, "训练课")]),
            c("邓超", "优米电商", "运营", "133-1000-0017", "dengchao@youmi.cn", "合作过一次",
              .ordinary, [i(400, .email, "问过合作事宜"), i(700, .meeting, "行业峰会偶遇")]),
            c("崔楠", "青禾农业", "技术员", "132-1000-0018", "cuinan@qinghe.cn", "老家邻居",
              .ordinary, [i(60, .wechat, "家人近况")]),
            c("潘晨", "云帆航空", "地勤主管", "131-1000-0019", "panchen@yunfan.cn", "出行认识的",
              .ordinary, [i(250, .phone, "帮忙订过票")]),
            c("袁芳", "睿哲律所", "律师", "130-1000-0020", "yuanfang@ruizhe.cn", "咨询过法律问题",
              .ordinary, [i(20, .email, "咨询合同条款")]),
        ]
    }
}
