lv1_head :: RandomWeightedBranch(0,1);
lv1_head[0] -> lv2_head_1 :: RandomWeightedBranch(0,1);
lv1_head[1] -> lv2_head_2 :: RandomWeightedBranch(0,1);
lv2_head_1[0] -> lv3_head_1 :: RandomWeightedBranch(0,1);
lv2_head_1[1] -> lv3_head_2 :: RandomWeightedBranch(0,1);
lv2_head_2[0] -> lv3_head_3 :: RandomWeightedBranch(0,1);
lv2_head_2[1] -> lv3_head_4 :: RandomWeightedBranch(0,1);
lv3_head_1[0] -> L2Forward(method 2) -> ToOutput();
lv3_head_1[1] -> L2Forward(method 2) -> ToOutput();
lv3_head_2[0] -> L2Forward(method 2) -> ToOutput();
lv3_head_2[1] -> L2Forward(method 2) -> ToOutput();
lv3_head_3[0] -> L2Forward(method 2) -> ToOutput();
lv3_head_3[1] -> L2Forward(method 2) -> ToOutput();
lv3_head_4[0] -> L2Forward(method 2) -> ToOutput();
lv3_head_4[1] -> L2Forward(method 2) -> ToOutput();